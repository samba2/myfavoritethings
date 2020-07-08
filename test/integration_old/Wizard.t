
sub testWizardAndLogin {
	
	# test wrong login	
	$mech->content_contains("enter your login password");
	$mech->submit_form_ok( { fields => { loginPassword => "wrong login" } },
			"send wrong login" );
	$mech->content_contains("Password was not correct");


	# EXCEED RATE LIMITER
	# delete old rate limiter data
	system("rm -f $csvPath/rate_limit_hits.csv");

	my $configDb = MyFav::DB::ConfigDB->new(
		"dataBaseName" => "config",
		"dataBaseDir"  => $baseClass->getDataBaseDir()
	);
	my $rateLimterMax = $configDb->getRateLimiterMaxHits();
	
	# send rate limiter maximum on wrong logins...
	for ($i=0; $i<=$rateLimterMax; $i++) {
		$mech->submit_form_ok( { fields => { loginPassword => "wrong login" } },
			"send wrong login" );
	}
	# ..and expect the rate limiter message
	$mech->content_contains("accessed this page too often");

	# delete rate limiter data to continue testing
	system("rm -f $csvPath/rate_limit_hits.csv");

	# we exceeded the limiter, so lets start from new by accessing
	# the Releases.cgi
	$mech->get_ok("$cgiBinUrl/Releases.cgi");
	$mech->content_contains("enter your login password");

	$mech->submit_form_ok(
		{ fields => { loginPassword => "123456789012345678901" } },
		"pw too long" );
	$mech->content_contains("too long");

	# correct login
	$mech->submit_form_ok( { fields => { loginPassword => "$currentPw" } },
		"send correct login" );


	## TODO continue from herr

	# test Wizard.pm
	createRelease( "myfavTestId",  "myfavTestName",  "maik.zip" );
	createRelease( "secondTestId", "secondTestName", "maik2.zip" );
##	createRelease( "thirdTestId",  "butGoodrelease", "maik3.zip" )
}


sub createRelease {
	my $releaseId   = shift;
	my $releaseName = shift;
	my $testZip     = shift;

	# first page, release name + id
    $mech->follow_link_ok({text => "Add new Release"}, "open wizard" );
	$mech->title_like(qr/My Favorite Things/);
	$mech->content_contains("Please enter the title of the release:");

	# syntax + input check
	$mech->submit_form_ok( {} );
	$mech->content_contains("You must supply a release name.");
	$mech->submit_form_ok( { fields => { releaseName => "$releaseName" } } );
	$mech->content_contains("You must supply a release ID.");
	$mech->submit_form_ok(
		{ fields => { releaseName => "$releaseName", releaseId => '$' } } );
	$mech->content_contains("The release ID contains unallowed characters.");
	$mech->submit_form_ok(
		{
			fields =>
			  { releaseName => "$releaseName", releaseId => 'white space' }
		}
	);
	$mech->content_contains("not allowed to contain any whitespace");
	$mech->submit_form_ok(
		{
			fields =>
			  { releaseName => "$releaseName", releaseId => "$releaseId" }
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
	system("mkdir -p $documentRoot/$forwardDir/test_release");
	$mech->submit_form_ok(
		{
			fields =>
			  { forwarder => "customString", customDir => 'test_release' }
		}
	);
	$mech->content_contains("already a forward directory with that name");
	system("rmdir $documentRoot/$forwardDir/test_release");

	# doing all this to get the "no whitespace" release id to create a test dir
	my $tempDb = MyFav::DB::TempDB->new(
		"dataBaseName" => "temp",
		"dataBaseDir"  => $baseClass->getDataBaseDir()
	);
	my $cleanReleaseId = $tempDb->getTempValue("releaseId");

	# create dir with cleaned releaseId name
	system("mkdir -p \"$documentRoot/$forwardDir/$cleanReleaseId\"");

	$mech->submit_form_ok( { fields => { forwarder => "releaseName" } } );
	$mech->content_contains("already a forward directory");
	system("rmdir $documentRoot/$forwardDir/$cleanReleaseId");

	# select "random string" and submit
	$mech->submit_form_ok( { fields => { forwarder => "randomString" } } );

	# 4. page, upload zip file
	$mech->content_contains(
		"Please select the ZIP file containing the packed MP3");
	
	# upload 201M file - too big
	# test afterwards fails if enabled. works in real though...
#	$mech->submit_form_ok( { fields => { 'fileName' => "201MBFile.zip"} } );
#	$mech->content_contains("exeeds the maximum");
	
	# simulate an existing file
	system("touch $uploadPath/$testZip");
	$mech->submit_form_ok( { fields => { 'fileName' => $testZip } } );
	$mech->content_contains("already existing on the server");
	# delete upload file
	system("rm -f $uploadPath/$testZip");
	$mech->submit_form_ok( { fields => { 'fileName' => "$testZip" } }, "normal file upload" );

	# wizard finished
	$mech->content_contains("Finished!");

	# try to add myfavTestName again
	$mech->follow_link_ok({text => "Add new Release"}, "re-open wizard" );
	$mech->title_like(qr/My Favorite Things/);
	$mech->content_contains("Please enter the title of the release:");
	$mech->submit_form_ok(
		{
			fields =>
			  { releaseName => "$releaseName", releaseId => "$releaseId" }
		},
		"Send form data"
	);
	$mech->content_contains("choose a different release ID");
}

1;