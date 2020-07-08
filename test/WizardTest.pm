package WizardTest;
use base qw(Test::Class);
use Test::More;
use Test::WWW::Mechanize;

use TestContainer;

use v5.10;


sub startup : Test(startup) {
    $self = shift;
    $self->{test_container} = TestContainer::start_and_block_until_available('debug' => 1);
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
 
sub shutdown : Test(shutdown) {
    shift->{test_container}->stop();
}


sub test_0010_wrong_login: Test {
    my $mech = shift->{mech};

	$mech->content_contains("enter your login password");
	$mech->submit_form_ok( { fields => { loginPassword => "wrong login" } },
			"send wrong login" );
	$mech->content_contains("Password was not correct");
}

1;