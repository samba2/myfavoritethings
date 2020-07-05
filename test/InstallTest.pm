package InstallTest;
use base qw(Test::Class);
use Test::More;
use Test::WWW::Mechanize;

use TestContainer;

use v5.10;

sub startup : Test(startup) {
    $self = shift;
    my $container_id = TestContainer->new();
    $container_id->start();
    $container_id->block_until_available();
    $self->{container_id} = $container_id;
    $self->{mech} = Test::WWW::Mechanize->new;

}
 
sub shutdown : Test(shutdown) {
    shift->{container_id}->stop();
}

sub test_0010_shows_welcome_message: Test {
    my $mech = shift->{mech};

    $cgi_bin_url = "http://localhost/cgi-bin/MyFavoriteThings/cgi";
	$mech->get_ok("$cgi_bin_url/install.cgi");
	$mech->content_contains("Welcome to the 'My Favorite Things' Installer");
}

sub test_0020_entering_password_is_enforced: Test {
    my $mech = shift->{mech};
    $mech->submit_form_ok( {} );
	$mech->content_contains("You have to fill out all password fields.");
}

sub test_0030_one_password_field_missing: Test {
    my $mech = shift->{mech};
	$mech->submit_form_ok( { fields => { newPassword1 => "1234" } },
		"leave one empty" );
	$mech->content_contains("You have to fill out all password fields.");
}

sub test_0040_password_too_short: Test {
    my $mech = shift->{mech};
	$mech->submit_form_ok(
		{ fields => { newPassword1 => "1234", newPassword2 => "1234" } },
		"too short" );
	$mech->content_contains("needs to be at least");
}

sub test_0050_password_too_long: Test {
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

sub test_0060_no_whitespace_in_password: Test {
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

sub test_0060_no_whitespace_in_password: Test {
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

sub test_0070_passwords_not_identical: Test {
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

sub test_0080_contains_invalid_characters: Test {
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

sub test_0090_all_good: Test {
    my $mech = shift->{mech};
    return "TODO fix this";
    
	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => "12345678",
				newPassword2 => "12345678",
				forwarderDir => "DigitalDownload/promo",
				cssDir       => "myfavCss"
			}
		},
		"everything fine"
	);

	$mech->content_contains("Please enter your login password");
}

1;