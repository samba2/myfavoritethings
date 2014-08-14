sub testLogin {
    $mech->get_ok("$cgiBinUrl/Releases.cgi");
    
    # test wrong login  
    $mech->content_contains("enter your login password");
    $mech->submit_form_ok( { 
        fields => { loginPassword => "wrong login" } },
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
     
     # we are inside
    $mech->content_contains("Manage Releases");    

    # logout again
    $mech->follow_link_ok({text => "Logout"}, "logging out" );
    $mech->content_contains("Please enter your login password"); 
}
	


1;