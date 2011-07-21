package test51_statusFileMissing;

sub runTests {
my $sel = $main::sel;
$sel->open_ok("/cgi-bin/cgi/Releases.cgi");
$sel->type_ok("loginPassword", "newpassword");
$sel->click_ok("css=input[type=submit]");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("link=Add new Release");
$sel->wait_for_page_to_load_ok("30000");
$sel->type_ok("releaseName", "test release 1");
$sel->type_ok("releaseId", "tr1");
$sel->click_ok("css=input[type=submit]");
$sel->wait_for_page_to_load_ok("30000");
$sel->type_ok("codeCount", "10");
$sel->click_ok("css=input[type=submit]");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("releaseName");
$sel->is_text_present_ok("http://myfav.org/DigitalDownload/promo/tr1");
$sel->click_ok("css=input[type=submit]");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("uploadLater");
$sel->click_ok("css=input[type=submit]");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("Congratulations");
$sel->click_ok("link=Manage Releases");
$sel->wait_for_page_to_load_ok("30000");
$sel->select_ok("releaseId", "label=test release 1");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("File hasn't been uploaded");
$sel->is_text_present_ok("File missing");
$sel->click_ok("showDetails");

#my $publicUrl = $sel->is_text_present("http://myfav.org/DigitalDownload/promo/tr1/");

$sel->click_ok("css=span.ui-icon.ui-icon-closethick");
$sel->click_ok("link=Delete Release");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("link=Yes");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("link=Logout");
$sel->wait_for_page_to_load_ok("30000");
}

1;
