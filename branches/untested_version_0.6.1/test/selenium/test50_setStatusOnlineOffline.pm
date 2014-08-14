package test50_setStatusOnlineOffline;

sub runTests {
my $sel = $main::sel;
$sel->open_ok("/cgi-bin/cgi/Releases.cgi");
$sel->type_ok("loginPassword", "newpassword");
$sel->click_ok("css=input[type=submit]");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("The Opensource One-Time Downloader");
$sel->click_ok("link=Add new Release");
$sel->wait_for_page_to_load_ok("30000");
$sel->type_ok("releaseName", "test release 1");
$sel->type_ok("releaseId", "tr1");
$sel->click_ok("css=input[type=submit]");
$sel->wait_for_page_to_load_ok("30000");
$sel->type_ok("codeCount", "10");
$sel->click_ok("css=input[type=submit]");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("css=input[type=submit]");
$sel->wait_for_page_to_load_ok("30000");
$sel->type_ok("fileName", $main::uploadFilePath);
$sel->click_ok("upload");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("Congratulations. You have successfully created a new release.");
$sel->click_ok("link=Manage Releases");
$sel->wait_for_page_to_load_ok("30000");
$sel->select_ok("releaseId", "label=test release 1");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("Online");
$sel->click_ok("changeReleaseStatus");
$sel->click_ok("radioSetOfflineNow");
$sel->click_ok("buttonOK");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("Offline");
$sel->click_ok("changeReleaseStatus");
$sel->is_text_present_ok("Do you want to set the release \"test release 1\" online?");
$sel->click_ok("buttonOK");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("link=Delete Release");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("link=Yes");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("Release 'test release 1' has been successfully deleted.");
$sel->click_ok("link=Logout");
$sel->wait_for_page_to_load_ok("30000");
}

1;