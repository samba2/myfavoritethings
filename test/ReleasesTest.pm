package ReleasesTest;
use base qw(Test::Class);
use Test::More;
use Test::WWW::Mechanize;

use TestContainer;

use strict;
use v5.10;


sub startup : Test(startup) {
    my $self = shift;
    $self->{test_container} = TestContainer::start_and_block_until_available();
    my $mech = Test::WWW::Mechanize->new;
    $self->{mech} = $mech;

    # install
    my $cgi_bin_url = "http://localhost/cgi-bin/MyFavoriteThings/cgi";
	$mech->get_ok("$cgi_bin_url/install.cgi");

	$mech->submit_form(
		
			fields => {
				newPassword1 => "12345678",
				newPassword2 => "12345678",
				forwarderDir => "DigitalDownload/promo",
				cssDir       => "myfavCss"
			}
		
	);

    # login
    $mech->submit_form(fields => { loginPassword => "12345678" });

    # create test release
    $mech->follow_link(text => "Add new Release");
	$mech->submit_form(fields => { releaseName => "AN_AWESOME_RELEASE", releaseId => "RELEASE001" });
	$mech->submit_form(fields => { codeCount => "50" });
	$mech->submit_form(fields => { forwarder => "randomString" });
	$mech->submit_form(fields => { 'fileName' => "goodmusic.zip" });
	$mech->content_contains("Finished!");
}
 
sub shutdown : Test(shutdown) {
    shift->{test_container}->stop();
}


sub test_0010_no_release_details_are_displayed: Test {
    my $mech = shift->{mech};

	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi");
    $mech->submit_form_ok({fields => { loginPassword => "12345678" }});

	$mech->content_contains("Select a release");
	$mech->content_unlike( qr/Release Name/ );
}

sub test_0020_no_release_details_when_called_with_wrong_parameter: Test {
    my $mech = shift->{mech};
	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi?blu=bla");
	$mech->content_unlike( qr/Release Name/ );
}

sub test_0030_call_with_wrong_release_id_si_ignored: Test {
    my $mech = shift->{mech};
	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi?releaseId=notexisting");
	$mech->content_unlike( qr/Release Name/ );
}

sub test_0040_existing_release_can_be_selected: Test {
    my $mech = shift->{mech};
	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi?releaseId=RELEASE001");
	$mech->content_contains("Select a release");
	$mech->content_contains("AN_AWESOME_RELEASE");
	$mech->content_contains("../upload_files/goodmusic.zip");
}

sub test_0050_use_menu: Test {
    my $mech = shift->{mech};
	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi");
  	$mech->follow_link_ok({text => "Manage Releases"}, "open releases" );
	$mech->content_contains("Select a release");
	$mech->content_contains("AN_AWESOME_RELEASE");

	$mech->submit_form_ok( { fields => { releaseId => 'RELEASE001' } }, "Select release" );
	$mech->content_contains("Public download URL");
	$mech->content_contains("../upload_files/goodmusic.zip");
}

sub test_0060_no_download_code_reset_when_not_used: Test {
    my $self = shift;
    my $mech = $self->{mech};
    my $test_container = $self->{test_container};
    my $valid_download_code = $test_container->execute("cat /usr/local/apache2/cgi-bin/MyFavoriteThings/data/codes_for_RELEASE001.csv | tail -n 1 | cut -d ',' -f 1");

	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi");
  	$mech->follow_link(text => "Manage Releases");
	$mech->submit_form(fields => { releaseId => 'RELEASE001' });

	$mech->follow_link_ok({text => "Code Status"}, "open 'code status'");
	$mech->content_contains("Please enter the code you want to check");
	$mech->submit_form_ok( { fields => { downloadCode => '$%' } }, "Invalid chars..." );
	$mech->content_contains("invalid characters");
	$mech->submit_form_ok( { fields => { downloadCode => "1234" } }, "Enter Wrong code to reset" );
	$mech->content_contains("not existing");	

	$mech->submit_form_ok( { fields => { downloadCode => "$valid_download_code" } } );
	$mech->content_contains("has been not requested so far");	
}

sub test_0070_reset_download_code: Test {
    my $self = shift;
    my $mech = $self->{mech};
    my $test_container = $self->{test_container};
    my $valid_download_code = $test_container->execute("cat /usr/local/apache2/cgi-bin/MyFavoriteThings/data/codes_for_RELEASE001.csv | tail -n 1 | cut -d ',' -f 1");

	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi");
  	$mech->follow_link(text => "Manage Releases");
	$mech->submit_form(fields => { releaseId => 'RELEASE001' });
	$mech->follow_link(text => "Code Status");

    $test_container->execute("sed -i 's/unused/used/g' /usr/local/apache2/cgi-bin/MyFavoriteThings/data/codes_for_RELEASE001.csv");
	$mech->submit_form_ok( { fields => { downloadCode => "$valid_download_code" } } );
	$mech->content_contains("has expired");
	$mech->content_contains("Set code to 'unused.'");

	# # reset code to unused
	$mech->follow_link_ok( {url_regex => qr/(?i:finishCodeStatus)/ }, "Follow the 'reset code' link.." );
	$mech->content_contains("The code has been reset to 'unused'");

}

sub test_0080_csv_export: Test {
    my $self = shift;
    my $mech = $self->{mech};

	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi");
  	$mech->follow_link(text => "Manage Releases");
	$mech->submit_form(fields => { releaseId => 'RELEASE001' });

	$mech->follow_link_ok({text => "Export CSV-File"}, "try csv export" );
	$mech->content_contains("code,status,timestamp,remotehost,useragent", "found csv table header");
	$mech->content_contains(",used,,,,", "found a used collumn");
}

sub test_0090_pdf_export: Test {
    my $self = shift;
    my $mech = $self->{mech};

	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi");
  	$mech->follow_link(text => "Manage Releases");
	$mech->submit_form(fields => { releaseId => 'RELEASE001' });

	$mech->follow_link_ok({text => "Export Download-Vouchers"}, "try pdf export" );
	$mech->content_contains("%PDF", "found pdf file header");
	$mech->content_contains("Download powered", "found some pdf content");
}
		
sub test_0100_delete_release: Test {
    my $self = shift;
    my $mech = $self->{mech};

	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi");
  	$mech->follow_link(text => "Manage Releases");
	$mech->submit_form(fields => { releaseId => 'RELEASE001' });

	$mech->follow_link_ok({text => "Delete Release"}, "request deleting release" );
	$mech->content_contains("Do you really want to");
	$mech->follow_link_ok({text => "Yes"}, "accept deleting release" );
	$mech->content_contains("Release 'AN_AWESOME_RELEASE' has been successfully deleted");
}
		
sub test_0110_change_password: Test {
    my $self = shift;
    my $mech = $self->{mech};

	$mech->get("http://localhost/cgi-bin/MyFavoriteThings/cgi/Releases.cgi");
  	$mech->follow_link_ok({text => "Change Password"}, "change pw" );
	$mech->content_contains("Your old password");
	$mech->submit_form_ok( { fields => { oldPassword => "12345678" } },
		"enter only old password" );
	$mech->content_contains("fill out all password fields");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "12345678",
				newPassword1 => "hash",
				newPassword2 => "hash"
			}
		},
		"too short"
	);
	$mech->content_contains("needs to be at least");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "12345678",
				newPassword1 => "123456789012345678901",
				newPassword2 => "123456789012345678901"
			}
		},
		"too long"
	);
	$mech->content_contains("at maximum");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "12345678",
				newPassword1 => "12345678",
				newPassword2 => "12345678"
			}
		},
		"3x the same"
	);
	$mech->content_contains("not allowed to be identical");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "12345678",
				newPassword1 => "new pw",
				newPassword2 => "new pw"
			}
		},
		"not equal"
	);
	$mech->content_contains("not allowed to contain whitespaces");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "12345678",
				newPassword1 => 'ßpasswd',
				newPassword2 => 'ßpasswd'
			}
		},
		"inval. chars"
	);
	$mech->content_contains("contains invalid characters");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "12345678",
				newPassword1 => "IamAnewPassword",
				newPassword2 => "IamAnewPassword"
			}
		},
		"good"
	);
	$mech->content_contains("changed successfully");
}

1;