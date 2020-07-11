package InstallOkTest;
use base qw(Test::Class);
use Test::More;
use Test::WWW::Mechanize;

use TestContainer;

use strict;
use v5.10;

sub all_good: Tests {
    my $test_container = TestContainer::start_and_block_until_available();
    my $mech = Test::WWW::Mechanize->new;
    
	$mech->get_ok("http://localhost/cgi-bin/MyFavoriteThings/cgi/install.cgi");
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