package InstallTest;
use base qw(Test::Class);
use Test::More;
use Test::WWW::Mechanize;

use strict;
use TestContainer;

use v5.10;

sub startup : Test(startup) {
    my $self = shift;
    $self->{test_container} = TestContainer::start_and_block_until_available();
    $self->{mech} = Test::WWW::Mechanize->new;
}
 
sub shutdown : Test(shutdown) {
    shift->{test_container}->stop();
}

sub test_0010_shows_welcome_message: Tests {
    my $mech = shift->{mech};
	$mech->get_ok("http://localhost/cgi-bin/MyFavoriteThings/cgi/install.cgi");
	$mech->content_contains("Welcome to the 'My Favorite Things' Installer");
}

sub test_0020_entering_password_is_enforced: Tests {
    my $mech = shift->{mech};
    $mech->submit_form_ok( {} );
	$mech->content_contains("You have to fill out all password fields.");
}

sub test_0030_one_password_field_missing: Tests {
    my $mech = shift->{mech};
	$mech->submit_form_ok( { fields => { newPassword1 => "1234" } },
		"leave one empty" );
	$mech->content_contains("You have to fill out all password fields.");
}

sub test_0040_password_too_short: Tests {
    my $mech = shift->{mech};
	$mech->submit_form_ok(
		{ fields => { newPassword1 => "1234", newPassword2 => "1234" } },
		"too short" );
	$mech->content_contains("needs to be at least");
}

sub test_0050_password_too_long: Tests {
    my $mech = shift->{mech};
	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => "123456789012345678901",
				newPassword2 => "123456789012345678901"
			}
		},
		"too long"
	);
	$mech->content_contains("characters at maximum");
}

sub test_0060_no_whitespace_in_password: Tests {
    my $mech = shift->{mech};
	$mech->submit_form_ok(
		{
			fields =>
			  { newPassword1 => "white space", newPassword2 => "white space" }
		},
		"white space"
	);
	$mech->content_contains("not allowed to contain whitespaces.");
}

sub test_0070_passwords_not_identical: Tests {
    my $mech = shift->{mech};
	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => "notidentical",
				newPassword2 => "not-identical"
			}
		},
		"not identical"
	);
	$mech->content_contains("password was not entered two times identical");
}

sub test_0080_contains_invalid_characters: Tests {
    my $mech = shift->{mech};
	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => '[12345',
				newPassword2 => '[12345'
			}
		},
		"inval chars"
	);
	$mech->content_contains("contains invalid characters");
}

sub test_0100_forward_dir_already_exists: Tests {
	my $self = shift;
    my $mech = $self->{mech};
	my $test_container = $self->{test_container};

	$test_container->execute("mkdir -p /usr/local/apache2/htdocs/DigitalDownload/promo");
	
	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => "12345678",
				newPassword2 => "12345678",
				forwarderDir => "DigitalDownload/promo"
			}
		},
		"forward dir exists"
	);

	$mech->content_contains("The central web directory");
	$test_container->execute("rm -rf /usr/local/apache2/htdocs/DigitalDownload/");
}

sub test_0110_css_dir_already_exists: Tests {
	my $self = shift;
    my $mech = $self->{mech};
	my $test_container = $self->{test_container};

	$test_container->execute("mkdir -p /usr/local/apache2/htdocs/MYFAVCSS");
	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => "12345678",
				newPassword2 => "12345678",
				forwarderDir => "download",
				cssDir       => "MYFAVCSS"
			}
		},
		"css dir exists"
	);
	$mech->content_contains("The style sheet directory");
	$test_container->execute("rmdir /usr/local/apache2/htdocs/MYFAVCSS");
}

sub test_0120_css_dir_has_no_write_permission: Tests {
	my $self = shift;
    my $mech = $self->{mech};
	my $test_container = $self->{test_container};

	my $old_permissions = $test_container->execute("stat -c '%a' /usr/local/apache2/htdocs");
	$test_container->execute("chmod 500 /usr/local/apache2/htdocs");
	
	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => "12345678",
				newPassword2 => "12345678",
				forwarderDir => "download",
				cssDir       => "MYFAVCSS"
			}
		},
        "no css copy exception"
    );
    $mech->content_contains("Couldn't copy the css-files");
	
	$test_container->execute("chmod $old_permissions /usr/local/apache2/htdocs");
}

1;