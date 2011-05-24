
sub installTest {
	$mech->get_ok("$cgiBinUrl/install.cgi");
	$mech->content_contains("Welcome to the 'My Favorite Things' Installer");
	$mech->submit_form_ok( {} );
	$mech->content_contains("You have to fill out all password fields.");
	$mech->submit_form_ok( { fields => { newPassword1 => "1234" } },
		"leave one empty" );
	$mech->content_contains("You have to fill out all password fields.");
	$mech->submit_form_ok(
		{ fields => { newPassword1 => "1234", newPassword2 => "1234" } },
		"too short" );
	$mech->content_contains("needs to be at least");
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
	$mech->submit_form_ok(
		{
			fields =>
			  { newPassword1 => "white space", newPassword2 => "white space" }
		},
		"white space"
	);
	$mech->content_contains("not allowed to contain whitespaces.");
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

	# create tmp dir
	system("mkdir -p $documentRoot/$forwardDir");
	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => $currentPw,
				newPassword2 => $currentPw,
				forwarderDir => "$forwardDir"
			}
		},
		"forward dir exists"
	);
	$mech->content_contains("The central web directory");
	system("rm -rf $documentRoot/$forwardDirTopLevel");

	system("mkdir -p $documentRoot/$cssDir");
	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => $currentPw,
				newPassword2 => $currentPw,
				forwarderDir => "$forwardDir",
				cssDir       => "$cssDir"
			}
		},
		"css dir exists"
	);
	$mech->content_contains("The style sheet directory");
	system("rmdir $documentRoot/$cssDir");

    system("chmod 0500 $documentRoot");
    $mech->submit_form_ok(
        {
            fields => {
                newPassword1 => $currentPw,
                newPassword2 => $currentPw,
                forwarderDir => "$forwardDir",
                cssDir       => "$cssDir"
            }
        },
        "no css copy exception"
    );
    $mech->content_contains("Couldn't copy the css-files");

    &bootstrapTestEnvironment;
    $mech->get_ok("$cgiBinUrl/install.cgi");

	
    system("chown root $cgiPath/install.cgi");
    system("chmod a+rx $cgiPath/install.cgi");

    $mech->submit_form_ok(
        {
            fields => {
                newPassword1 => $currentPw,
                newPassword2 => $currentPw,
                forwarderDir => "$forwardDir",
                cssDir       => "$cssDir"
            }
        },
        "no chmod of install.cgi after install exception"
    );
    $mech->content_contains("I could not remove the execution rights");


    &bootstrapTestEnvironment;
    $mech->get_ok("$cgiBinUrl/install.cgi");

	$mech->submit_form_ok(
		{
			fields => {
				newPassword1 => $currentPw,
				newPassword2 => $currentPw,
				forwarderDir => "$forwardDir",
				cssDir       => "$cssDir"
			}
		},
		"everything fine"
	);

	$mech->content_contains("Please enter your login password");
}

1;
