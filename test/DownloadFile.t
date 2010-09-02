
sub testDownloadFile {
	my $releaseId = shift;

	# lower case for DBI::PurePerl problems, see General.pm, sub getDataBaseName
	my $releaseDbName = $baseClass->getReleaseDbPrefix() . $releaseId;

	my $releaseDb = MyFav::DB::ReleaseDB->new(
		"dataBaseName" => $releaseDbName,
		"dataBaseDir"  => $baseClass->getDataBaseDir()
	);
	
	my $configDb = MyFav::DB::ConfigDB->new(
		"dataBaseName" => "config",
		"dataBaseDir"  => $baseClass->getDataBaseDir()
	);

	my $downloadUrl = $configDb->getDownloadUrl("myfavTestId");

## call without parameters
	$mech->get_ok("$cgiBinUrl/DownloadFile.cgi");
	$mech->content_contains("This download service is provided by");

	# call with wrong parameter
	$mech->get_ok("$cgiBinUrl/DownloadFile.cgi?blu=bla");
	$mech->content_contains("This download service is provided by");

	# call with correct "r" parameter but with wrong hash
	$mech->get_ok("$cgiBinUrl/DownloadFile.cgi?r=3jykCKU7VCnwoCJ2SzTt+");
	$mech->content_contains("This download service is provided by");


	# correct call with releaseHash of myfavTestId
	$mech->get_ok($downloadUrl);
	$mech->follow_link_ok( {n=>1}, "follow url inside frame" );
#	$mech->get_ok("$cgiBinUrl/DownloadFile.cgi?r=3jykCKU7VCnwoCJ2SzTt%2BA");
	$mech->content_contains("Please enter the download code");

	# input unvalid code
	$mech->submit_form_ok( { fields => { downloadCode => "12345" } },
		"Send unvalid code." );
	$mech->content_contains("The code you have entered is not valid.");

	# test rate limiter
	# delete old rate limiter data
	system("rm -f $csvPath/rate_limit_hits.csv");

	my $rateLimterMax = $configDb->getRateLimiterMaxHits();
	
	# send rate limiter maximum on wrong logins...
	for ($i=0; $i<=$rateLimterMax; $i++) {
		$mech->submit_form_ok( { fields => { downloadCode => "12345" } },
			"Send unvalid code." );
	}
	# ..and expect the rate limiter message
	$mech->content_contains("accessed this page too often");

	# delete rate limiter data to continue testing
	system("rm -f $csvPath/rate_limit_hits.csv");
	
	# rate limiter finished

	# reload page again
	$mech->get_ok($downloadUrl);
	$mech->follow_link_ok( {n=>1}, "follow url inside frame" );
	# correct code
	my $code = $releaseDb->getFirstCode();

	$mech->submit_form_ok( { fields => { downloadCode => "$code" } },
		"Send valid code $code." );
	$mech->content_contains("Thanks for your purchase");

 	my @links = $mech->find_all_links( url_regex => qr/stream/ );
    $mech->links_ok( \@links, 'link to streamFile runmode works' );

	# reenter code
	$mech->get_ok($downloadUrl);
	$mech->follow_link_ok( {n=>1}, "follow url inside frame" );
	$mech->submit_form_ok(
		{ fields => { downloadCode => "$code" } },
		"Send valid code $code again. Should be alright"
	);
	$mech->content_contains("Thanks for your purchase");

# test expiration
# - take old timestamp and move one week back. the expirationTimer should be smaller
	my $timeStamp = $releaseDb->getTimeStamp($code);
	my $download  = MyFav::SubApps::DownloadFile->new();
	$timeStamp = $download->getEpochTime($timeStamp);
	$timeStamp = $timeStamp - 604800;                   # move backward one week
	my $timeString = time2str( '%Y%m%d%H%M%S', $timeStamp );
	
	# due to DBI::PurePerl problems with mixed case db names
	my $lowCaseReleaseDbName = lc($releaseDbName);
	$releaseDb->writeToDataBase(
		"UPDATE $lowCaseReleaseDbName SET timeStamp='$timeString' WHERE code='$code'");

	# now see if the code has been really expired
	$mech->get_ok($downloadUrl);
	$mech->follow_link_ok( {n=>1}, "follow url inside frame" );
	$mech->submit_form_ok( { fields => { downloadCode => "$code" } },
		"Send expired code." );
	$mech->content_contains("The code you have entered has expired.");
}

1;
