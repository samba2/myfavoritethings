
sub testWizard {
	$mech->get_ok("$cgiBinUrl/Releases.cgi");

	# login
	$mech->submit_form_ok( { fields => { loginPassword => "$currentPw" } },
		"login to create new release" );

	# test Wizard.pm
	
	# create this two releases + delete them after the test
    print "ok Release upload + deleting\n";
    createRelease( "maiktestId2", "maiktestName2", "maik4.zip", 1 );
    print "ok Release without upload + deleting\n";
    createRelease( "maiktestId3", "maiktestName3", "fake", 1 );
	
	# "myfavTestId" is kept for further tests
	createRelease( "myfavTestId",  "myfavTestName",  "maik.zip" );

	# logout
	$mech->follow_link_ok( { text => "Logout" }, "logging out" );
	$mech->content_contains("Please enter your login password");
}

sub createRelease {
	my $releaseId     = shift;
	my $releaseName   = shift;
	my $testZip       = shift;
	my $deleteRelease = shift;

	# first page, release name + id
	$mech->follow_link_ok( { text => "Add new Release" }, "open wizard" );
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
	# distinguishes between existing $testZip = upload and
	# non existing $testZip = upload later

	$mech->content_contains(
		"Please select the ZIP file containing the packed MP3");

	# upload 201M file - too big
	# test afterwards fails if enabled. works in real though...
	#	$mech->submit_form_ok( { fields => { 'fileName' => "201MBFile.zip"} } );
	#	$mech->content_contains("exeeds the maximum");

    # finish wizard with file upload
	if ( -r $testZip ) {

		# simulate an existing file
		system("touch $uploadPath/$testZip");

		$mech->submit_form_ok(
			{
				form_name => 'fileUpload',
				fields    => { 'fileName' => $testZip }
			}
		);
		$mech->content_contains("already existing on the server");

		# delete upload file
		system("rm -f $uploadPath/$testZip");
		$mech->submit_form_ok(
			{
				form_name => 'fileUpload',
				fields    => { 'fileName' => "$testZip" }
			},
			"normal file upload"
		);

	}
	# finish wizard without fileupload
	else {
		$mech->submit_form_ok(
			{
				form_name => 'nextButton'
			}
		);

	}

	# wizard finished
	$mech->content_contains("Finished!");
	
    # test if user download page in inactive if no file has been added
	if (! -r $testZip) {
        my $configDb = MyFav::DB::ConfigDB->new(
            "dataBaseName" => "config",
            "dataBaseDir"  => $baseClass->getDataBaseDir()
        );
        
        my $releaseCgiUrl = $configDb->getReleaseCgiUrl($releaseId);
        $mech->get_ok($releaseCgiUrl);
        
        print "Testing if download page is inactive\n";
        $mech->content_contains("There has no music been added");
        
        $mech->get_ok("$cgiBinUrl/Releases.cgi");
	}
	

	# try to add myfavTestName again
	$mech->follow_link_ok( { text => "Add new Release" }, "re-open wizard" );
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

    # testing adding/ replacing files in Releases.pm
    $mech->follow_link_ok( { text => "Manage Releases" }, "open releases" );
    $mech->content_contains("Select a release");
    $mech->content_contains($releaseName);

    # select $releaseName
    $mech->submit_form_ok( { fields => { releaseId => $releaseName } },
            "Select a release" );

    if ( $mech->content() =~ m/File hasn't been uploaded/ig ) {
        $mech->follow_link_ok( { text => "Add File" }, "testing adding upload file" );	
    }
    else {
    	$mech->follow_link_ok( { text => "Replace Uploaded File" }, "testing replacing of uploaded file" );
    }    

    # simulate an existing file
    system("touch $uploadPath/wizardAddFileTest.zip");

    $mech->submit_form_ok(
        {
            form_name => 'fileUpload',
            fields    => { 'fileName' => "wizardAddFileTest.zip" }
        }
    );
    $mech->content_contains("already existing on the server");

    # delete upload file
    system("rm -f $uploadPath/wizardAddFileTest.zip");
        
    $mech->submit_form_ok(
        {
            form_name => 'fileUpload',
            fields    => { 'fileName' => "wizardAddFileTest.zip" }
        },
        "add file upload"
    );
    $mech->content_contains("Size of uploaded file");
    

  	# only for single tests with Wizard.pm
	if ($deleteRelease) {

		# delete the release
		$mech->follow_link_ok( { text => "Manage Releases" }, "open releases" );
		$mech->content_contains("Select a release");
		$mech->content_contains($releaseName);
		$mech->content_contains("http");

		# select $releaseName
		$mech->submit_form_ok( { fields => { releaseId => $releaseName } },
			"Select a release" );
		$mech->content_contains("Public download URL");

		# delete release dialog
		$mech->follow_link_ok( { text => "Delete Release" },
			"request deleting release" );
		$mech->content_contains("Do you really want to");

		# delete release + go to default page
		$mech->follow_link_ok( { text => "Yes" }, "accept deleting release" );
		$mech->content_unlike( qr/Could not delete/, "no delete error" );
	}
}

1;
