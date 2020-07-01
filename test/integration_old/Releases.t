
sub testReleases {
	my $releaseId = shift;
	my $newPw = shift;
	
	my $releaseDbName = $baseClass->getReleaseDbPrefix() . $releaseId;

	my $releaseDb = MyFav::DB::ReleaseDB->new(
		"dataBaseName" => $releaseDbName,
		"dataBaseDir"  => $baseClass->getDataBaseDir()
	);
	
	# just send an empty request, should give back empty status page
	$mech->get_ok("$cgiBinUrl/Releases.cgi");
	$mech->content_contains("Select a release");
	$mech->content_unlike( qr/Release Name/,
		"no release details are displayed" );

	# call with wrong parameter
	$mech->get_ok("$cgiBinUrl/Releases.cgi?blu=bla");
	$mech->content_unlike( qr/Release Name/,
		"no release details are displayed" );

	# call with wrong release id
	$mech->get_ok("$cgiBinUrl/Releases.cgi?releaseId=notexisting");
	$mech->content_unlike( qr/Release Name/,
		"no release details are displayed" );

	# correct call
	$mech->get_ok("$cgiBinUrl/Releases.cgi?releaseId=myfavTestId");
	$mech->content_contains("Select a release");
	$mech->content_contains("myfavTestName");
	$mech->content_contains("http");
	
	# so lets use the menu
	$mech->follow_link_ok({text => "Manage Releases"}, "open releases" );
	$mech->content_contains("Select a release");
	$mech->content_contains("myfavTestName");
	$mech->content_contains("http");
	
	# select myFavTestName
	$mech->submit_form_ok( { fields => { releaseId => 'myfavTestId' } }, "Select a release" );
	$mech->content_contains("Public download URL");
	
	# test reset code
	$mech->follow_link_ok({text => "Code Status"}, "open 'code status'" );
	$mech->content_contains("Please enter the code you want to check");
	$mech->submit_form_ok( { fields => { downloadCode => '$%' } }, "Invalid chars..." );
	$mech->content_contains("invalid characters");
	$mech->submit_form_ok( { fields => { downloadCode => "1234" } }, "Enter Wrong code to reset" );
	$mech->content_contains("not existing");	
		
	# get first code, should be used from previous download test	
	my $code = $releaseDb->getFirstCode();
	$mech->submit_form_ok( { fields => { downloadCode => "$code" } } );
	$mech->content_contains("has expired");
	$mech->content_contains("Set code to 'unused.'");
	
	# reset code to unused
	$mech->follow_link_ok( {url_regex => qr/(?i:finishCodeStatus)/ }, "Follow the 'reset code' link.." );
	$mech->content_contains("The code has been reset to 'unused'");
	
	# back to the menu
	$mech->follow_link_ok({text => "Manage Releases"}, "open releases" );
	$mech->submit_form_ok( { fields => { releaseId => 'myfavTestId' } }, "Select a release" );

	# text export options
	$mech->follow_link_ok({text => "Export CSV-File"}, "try csv export" );
	$mech->content_contains("code,status,timestamp,remotehost,useragent", "found csv table header");
	$mech->content_contains(",unused,,,,", "found one unused collumn");

	# back to the menu
	$mech->get_ok("$cgiBinUrl/Releases.cgi");
	$mech->follow_link_ok({text => "Manage Releases"}, "open releases" );
	$mech->submit_form_ok( { fields => { releaseId => 'myfavTestId' } }, "Select a release" );
	
	# pdf export options
	$mech->follow_link_ok({text => "Export Download-Vouchers"}, "try pdf export" );
	$mech->content_contains("%PDF", "found pdf file header");
	$mech->content_contains("Download powered", "found some pdf content");

	# back to the menu
	$mech->get_ok("$cgiBinUrl/Releases.cgi");
	$mech->follow_link_ok({text => "Manage Releases"}, "open releases" );
	$mech->submit_form_ok( { fields => { releaseId => 'myfavTestId' } }, "Select a release" );

	# delete release dialog
	$mech->follow_link_ok({text => "Delete Release"}, "request deleting release" );
	$mech->content_contains("Do you really want to");

	# delete release + go to default page
	$mech->follow_link_ok({text => "Yes"}, "accept deleting release" );
	$mech->content_unlike( qr/Could not delete/, "no delete error" );

	# change password
	$mech->follow_link_ok({text => "Change Password"}, "change pw" );
	$mech->content_contains("Your old password");
	$mech->submit_form_ok( { fields => { oldPassword => "$currentPw" } },
		"enter only old password" );
	$mech->content_contains("fill out all password fields");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "$currentPw",
				newPassword1 => "hash",
				newPassword2 => "hash"
			}
		},
		"too short"
	);
	$mech->content_contains("needs to be at least");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "$currentPw",
				newPassword1 => "123456789012345678901",
				newPassword2 => "123456789012345678901"
			}
		},
		"too long"
	);
	$mech->content_contains("at maximum");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "$currentPw",
				newPassword1 => "$currentPw",
				newPassword2 => "$currentPw"
			}
		},
		"3x the same"
	);
	$mech->content_contains("not allowed to be identical");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "$currentPw",
				newPassword1 => "new pw",
				newPassword2 => "new pw"
			}
		},
		"not equal"
	);
	$mech->content_contains("not allowed to contain whitespaces");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "$currentPw",
				newPassword1 => 'ßpasswd',
				newPassword2 => 'ßpasswd'
			}
		},
		"inval. chars"
	);
	$mech->content_contains("contains invalid characters");
	$mech->submit_form_ok(
		{
			fields => {
				oldPassword  => "$currentPw",
				newPassword1 => "$newPw",
				newPassword2 => "$newPw"
			}
		},
		"good"
	);
	$mech->content_contains("changed successfully");

	# logout
	$mech->follow_link_ok({text => "Logout"}, "logout" );
	$mech->content_contains("Please enter your login password");
}

1;