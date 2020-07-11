package DownloadFileTest;
use base qw(Test::Class);
use Test::More;
use Test::WWW::Mechanize;
use Time::Local;
use Date::Format;
 
use TestContainer;

use strict;
use v5.10;

sub startup : Test(startup) {
    my $self = shift;
    $self->{test_container} = TestContainer::start_and_block_until_available();
    my $mech = Test::WWW::Mechanize->new;
    $self->{mech} = $mech;

        # install
	$mech->get_ok("http://localhost/cgi-bin/MyFavoriteThings/cgi/install.cgi");
	$mech->submit_form(
			fields => {
				newPassword1 => "12345678",
				newPassword2 => "12345678",
				forwarderDir => "DigitalDownload/promo",
				cssDir       => "myfavCss"
			});

    # login
    $mech->submit_form(fields => { loginPassword => "12345678" });

    # create test release
    $mech->follow_link(text => "Add new Release");
	$mech->submit_form(fields => { releaseName => "AN_AWESOME_RELEASE", releaseId => "RELEASE001" });
	$mech->submit_form(fields => { codeCount => "50" });
	$mech->submit_form(fields => { forwarder => "releaseName" });
	$mech->submit_form(fields => { 'fileName' => "goodmusic.zip" });
	$mech->content_contains("Finished!");
}
 
sub shutdown : Test(shutdown) {
    shift->{test_container}->stop();
}

sub test_0010_check_basic_call: Test {
    my $mech = shift->{mech};

	$mech->get_ok("http://localhost/cgi-bin/MyFavoriteThings/cgi/DownloadFile.cgi", "call without parameters");
	$mech->content_contains("This download service is provided by");

	$mech->get_ok("http://localhost/cgi-bin/MyFavoriteThings/cgi/DownloadFile.cgi?blu=bla", "call with wrong parameter");
	$mech->content_contains("This download service is provided by");

	$mech->get_ok("http://localhost/cgi-bin/MyFavoriteThings/cgi/DownloadFile.cgi?r=3jykCKU7VCnwoCJ2SzTt+", 'call with correct "r" parameter but with wrong hash');
	$mech->content_contains("This download service is provided by");
}

sub test_0020_code_can_be_entered_when_called_with_correct_release_hash: Test {
    my $mech = shift->{mech};

	$mech->get_ok("http://localhost/DigitalDownload/promo/RELEASE001/");
	$mech->follow_link_ok( {n=>1}, "follow url inside frame" );
	$mech->content_contains("Please enter the download code");
}

sub test_0030_enter_invalid_code: Test {
    my $mech = shift->{mech};

	$mech->get("http://localhost/DigitalDownload/promo/RELEASE001/");
	$mech->follow_link(n=>1);

	$mech->submit_form_ok( { fields => { downloadCode => "12345" } },
		"Send unvalid code." );
	$mech->content_contains("The code you have entered is not valid.");
}

sub test_0040_rate_limit: Test {
    my $self = shift;
    my $mech = $self->{mech};
    my $test_container = $self->{test_container};
    my $rateLimterMax = 30;

    # reset rate limiter
    $test_container->execute("rm -f /usr/local/apache2/cgi-bin/MyFavoriteThings/data/rate_limit_hits.csv");
	
    $mech->get("http://localhost/DigitalDownload/promo/RELEASE001/");
	$mech->follow_link(n=>1);

	for (my $i=0; $i<=$rateLimterMax; $i++) {
		$mech->submit_form_ok( { fields => { downloadCode => "12345" } },
			"Send unvalid code." );
	}

	$mech->content_contains("accessed this page too often");

    # reset again
    $test_container->execute("rm -f /usr/local/apache2/cgi-bin/MyFavoriteThings/data/rate_limit_hits.csv");
}

sub test_0050_code_is_valid: Test {
    my $self = shift;
    my $mech = $self->{mech};
    my $test_container = $self->{test_container};

    my $valid_download_code = $test_container->execute("cat /usr/local/apache2/cgi-bin/MyFavoriteThings/data/codes_for_RELEASE001.csv | tail -n 1 | cut -d ',' -f 1");

    $mech->get("http://localhost/DigitalDownload/promo/RELEASE001/");
	$mech->follow_link(n=>1);
    $mech->submit_form_ok( { fields => { downloadCode => "$valid_download_code" } },
		"Send valid code." );
	$mech->content_contains("Thanks for your purchase");

 	my @links = $mech->find_all_links( url_regex => qr/stream/ );
    $mech->links_ok( \@links, 'link to streamFile runmode works' );

	# reenter code
    $mech->get("http://localhost/DigitalDownload/promo/RELEASE001/");
	$mech->follow_link(n=>1);
	$mech->submit_form_ok(
		{ fields => { downloadCode => "$valid_download_code" } },
		"Send valid code second time again. Should be alright"
	);
	$mech->content_contains("Thanks for your purchase");
}

sub test_0060_code_has_expired: Test {
    my $self = shift;
    my $mech = $self->{mech};
    my $test_container = $self->{test_container};
    my $expirationTimer = 3600; # set in ConfigDb

    my $valid_download_code = $test_container->execute("cat /usr/local/apache2/cgi-bin/MyFavoriteThings/data/codes_for_RELEASE001.csv | grep unused | tail -n 1 | cut -d ',' -f 1");

    $mech->get("http://localhost/DigitalDownload/promo/RELEASE001/");
	$mech->follow_link(n=>1);
    $mech->submit_form(fields => { downloadCode => "$valid_download_code" });
	$mech->content_contains("Thanks for your purchase");

    # get download time
    my $cmd = "cat /usr/local/apache2/cgi-bin/MyFavoriteThings/data/codes_for_RELEASE001.csv |  grep $valid_download_code | sed  -E 's/$valid_download_code,used,([0-9]{14}),.+/\\1/g'";
    my $downloadTimestamp = $test_container->execute($cmd);

    my $downloadTimestampEpoch = $self->getEpochTime($downloadTimestamp);

    # go back more than 1 h
    my $updatedDownloadTimestampEpoch = $downloadTimestampEpoch - $expirationTimer - 5;
    my $updatedDownloadTimestamp = time2str( '%Y%m%d%H%M%S', $updatedDownloadTimestampEpoch );

    # update new download time
    $cmd = "sed -i -E 's/($valid_download_code,used,)[0-9]{14}(,.+)/\\1$updatedDownloadTimestamp\\2/g' /usr/local/apache2/cgi-bin/MyFavoriteThings/data/codes_for_RELEASE001.csv";
    $test_container->execute($cmd);

    # try again
    $mech->get("http://localhost/DigitalDownload/promo/RELEASE001/");
	$mech->follow_link(n=>1);
    $mech->submit_form(fields => { downloadCode => "$valid_download_code" });
	$mech->content_contains("The code you have entered has expired.");
}

sub getEpochTime {
	my $self       = shift;
	my $timeString = shift;
	my $epochString;

	if ( $timeString =~ m/\A(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)\Z/ ) {
		my $year = $1;
		my $mon  = $2 - 1;    # handles the time local offset
		my $mday = $3;
		my $hour = $4;
		my $min  = $5;
		my $sec  = $6;

		$epochString = timelocal( $sec, $min, $hour, $mday, $mon, $year );
	}
	return $epochString;
}

1;