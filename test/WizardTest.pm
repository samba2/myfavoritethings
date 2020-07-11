package WizardTest;
use base qw(Test::Class);
use Test::More;
use Test::WWW::Mechanize;

use TestContainer;

use v5.10;


sub setup : Test(setup) {
    $self = shift;
    $self->{test_container} = TestContainer::start_and_block_until_available();
    $mech = Test::WWW::Mechanize->new;
    $self->{mech} = $mech;

    # install
    $cgi_bin_url = "http://localhost/cgi-bin/MyFavoriteThings/cgi";
	$mech->get_ok("$cgi_bin_url/install.cgi");

	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => "12345678",
				newPassword2 => "12345678",
				forwarderDir => "DigitalDownload/promo",
				cssDir       => "myfavCss"
			}
		}, "install MyFav");
    $mech->submit_form_ok({ fields => { loginPassword => "12345678" } }, "login" );
}
 
sub teardown : Test(teardown) {
    shift->{test_container}->stop();
}


sub create_new_release_journey: Test {
    my $mech = shift->{mech};
    my $test_container = $self->{test_container};

	# first page, release name + id
    $mech->follow_link_ok({text => "Add new Release"}, "open wizard" );
	$mech->title_like(qr/My Favorite Things/);
	$mech->content_contains("Please enter the title of the release:");

	# syntax + input check
	$mech->submit_form_ok( {} );
	$mech->content_contains("You must supply a release name.");
	$mech->submit_form_ok( { fields => { releaseName => "AN_AWESOME_RELEASE" } } );
	$mech->content_contains("You must supply a release ID.");
	$mech->submit_form_ok(
		{ fields => { releaseName => "AN_AWESOME_RELEASE", releaseId => '$' } } );
	$mech->content_contains("The release ID contains unallowed characters.");
	$mech->submit_form_ok(
		{
			fields =>
			  { releaseName => "AN_AWESOME_RELEASE", releaseId => 'white space' }
		}
	);
	$mech->content_contains("not allowed to contain any whitespace");
	$mech->submit_form_ok(
		{
			fields =>
			  { releaseName => "AN_AWESOME_RELEASE", releaseId => "RELEASE001" }
		}
	);

	# 2. page, number of codes
	$mech->content_contains("How many codes do you need?");
	$mech->submit_form_ok( { fields => { codeCount => "##" } } );
	$mech->content_contains("You have to enter a number");
	$mech->submit_form_ok( { fields => { codeCount => "50" } } );

	# 3. page, forwarder details
	$mech->content_contains("How do you want to setup the download URL");

	# create test dir to see if application acknowledges existence
    $test_container->execute("mkdir -p /usr/local/apache2/htdocs/DigitalDownload/promo/test_release");

	$mech->submit_form_ok(
		{
			fields =>
			  { forwarder => "customString", customDir => 'test_release' }
		}
	);
	$mech->content_contains("already a forward directory with that name");
	$test_container->execute("rm -rf /usr/local/apache2/htdocs/DigitalDownload/promo/*");

	# select "random string" and submit
	$mech->submit_form_ok( { fields => { forwarder => "randomString" } } );

	# 4. page, upload zip file
	$mech->content_contains(
		"Please select the ZIP file containing the packed MP3");
	
	# upload 201M file - too big
	# test afterwards fails if enabled. works in real though...
	$mech->submit_form_ok( { fields => { 'fileName' => "201MB.zip"} } );
	$mech->content_contains("exeeds the maximum");
	
	# simulate an existing file
	$test_container->execute("touch /usr/local/apache2/cgi-bin/MyFavoriteThings/upload_files/goodmusic.zip");
	$mech->submit_form_ok( { fields => { 'fileName' => "goodmusic.zip" } } );
	$mech->content_contains("already existing on the server");
	$test_container->execute("rm -f /usr/local/apache2/cgi-bin/MyFavoriteThings/upload_files/goodmusic.zip");

    # 5. now eventually upload to finish wizard
	$mech->submit_form_ok( { fields => { 'fileName' => "goodmusic.zip" } }, "normal file upload" );
	$mech->content_contains("Finished!", "done with the wizard");

    # 6. trying to add same thing again
	$mech->follow_link_ok({text => "Add new Release"}, "trying to add same release again" );
	$mech->title_like(qr/My Favorite Things/);
	$mech->content_contains("Please enter the title of the release:");
	$mech->submit_form_ok(
		{
			fields =>
			  { releaseName => "AN_AWESOME_RELEASE", releaseId => "RELEASE001" }
		},
		"Send form data"
	);
	$mech->content_contains("choose a different release ID");
}

1;