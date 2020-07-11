package LoginTest;
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
		},
		"everything setup"
	);

	$mech->content_contains("Please enter your login password");
}
 
sub teardown : Test(teardown) {
    shift->{test_container}->stop();
}


sub test_0010_wrong_login: Test {
    my $mech = shift->{mech};

	$mech->content_contains("enter your login password");
	$mech->submit_form_ok( { fields => { loginPassword => "wrong login" } },
			"send wrong login" );
	$mech->content_contains("Password was not correct");
}


sub test_0020_rate_limiter_kicks_in: Test {
    my $mech = shift->{mech};
    my $rateLimterMax = 30;  # this is the default config

	for ($i=0; $i<=$rateLimterMax; $i++) {
		$mech->submit_form_ok( { fields => { loginPassword => "wrong login" } },
			"send wrong login" );
	}

	# ..and expect the rate limiter message
	$mech->content_contains("accessed this page too often");
}

sub test_0030_too_long_password: Test {
    my $mech = shift->{mech};

	$mech->submit_form_ok(
		{ fields => { loginPassword => "123456789012345678901" } },
		"pw too long" );
	$mech->content_contains("too long");
}

sub test_0040_login_ok: Test {
    my $mech = shift->{mech};

	$mech->submit_form_ok(
		{ fields => { loginPassword => "12345678" } },
		"correct password" );
	$mech->content_contains("No releases found in the database");
}

1;