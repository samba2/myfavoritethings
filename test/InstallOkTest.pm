package InstallOkTest;
use base qw(Test::Class);
use Test::More;
use Test::WWW::Mechanize;

use TestContainer;

use v5.10;

sub all_good: Test {
    my $test_container = TestContainer::start_and_block_until_available();
    my $mech = Test::WWW::Mechanize->new;
    
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
		"everything fine"
	);

	$mech->content_contains("Please enter your login password");

    $test_container->stop();
}

1;