package test52_downloadExpired;

use MyFav::Base;
use MyFav::DB::ConfigDB;

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
$sel->type_ok("fileName", $main::uploadFilePath );
$sel->click_ok("upload");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("Congratulations. You have successfully created a new release.");
$sel->click_ok("link=Manage Releases");
$sel->wait_for_page_to_load_ok("30000");
$sel->select_ok("releaseId", "label=test release 1");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("Online");
$sel->click_ok("changeReleaseStatus");
$sel->click_ok("radioSetOfflineLater");
$sel->click_ok("txtDatePicker");
$sel->click_ok("css=span.ui-icon.ui-icon-circle-triangle-e");
$sel->click_ok("css=span.ui-icon.ui-icon-circle-triangle-e");
$sel->click_ok("link=11");
$sel->click_ok("txtDatePicker");
$sel->click_ok("//body/div[2]/div");
$sel->type_ok("txtDatePicker", "08/11/2031");
$sel->click_ok("buttonOK");
$sel->wait_for_page_to_load_ok("30000");
$sel->is_text_present_ok("Expires at 08/11/2031");
$sel->click_ok("showDetails");
$sel->click_ok("css=span.ui-icon.ui-icon-closethick");
$sel->open_ok("/DigitalDownload/promo/tr1/");
$sel->select_frame_ok("framename");
WAIT: {
    for (1..60) {
        if (eval { $sel->is_text_present("Thanks for purchasing \"test release 1\"") }) { pass; last WAIT }
        sleep(1);
    }
    fail("timeout");
}

my $configDb = MyFav::DB::ConfigDB->new(
    "dataBaseName" => "config",
    "dataBaseDir"  => $main::configDbDir
);

$configDb->updateStatus('tr1','01012010');

$sel->open_ok("/DigitalDownload/promo/tr1/");
$sel->select_frame_ok("framename");
$sel->is_text_present_ok("The download of this release has expired");

$sel->open_ok("/cgi-bin/cgi/Releases.cgi");
$sel->select_window_ok("null");
$sel->select_ok("releaseId", "label=test release 1");
$sel->wait_for_page_to_load_ok("30000");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("link=Delete Release");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("link=Yes");
$sel->wait_for_page_to_load_ok("30000");
$sel->click_ok("link=Logout");
$sel->wait_for_page_to_load_ok("30000");
}

1
