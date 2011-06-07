#!/usr/bin/perl -w

use strict;
use lib "../lib";

use MyFav::SubApps::Wizard;
use MyFav::SubApps::DownloadFile;
use MyFav::DB::TempDB;
use MyFav::DB::ConfigDB;
use Date::Format;

use Test::More tests => 252;
use Test::WWW::Mechanize;
use WWW::Mechanize::Link;

require("Login.t");
require("Wizard.t");
require("Releases.t");
require("DownloadFile.t");
require("Install.t");

our $cgiBinUrl       = 'http://myfav.org/cgi-bin/cgi';
our $documentRootUrl = 'http://myfav.org';
our $csvPath         = '../data';
our $uploadPath      = '../upload_files';
our $sessionDir      = "../sessions";
our $cgiPath         = "../cgi/";
our $documentRoot    = '/var/www';
our $forwardDir      = 'DigitalDownload/promo';
our ($forwardDirTopLevel) = $forwardDir =~ m/\A(.+)\//;
our $webLibDir       = 'myfavLibs';
our $currentPw       = 'a-zA-Z0-9_-.!"$%&';

our $randomReleaseId = int( rand(10000) );
our $mech            = Test::WWW::Mechanize->new;
our $baseClass       = MyFav::Base->new();

print "ok -- Start install procedure -- \n";

&bootstrapTestEnvironment;

# run test in Install.t
&installTest();

print "ok -- Testing Login.pm -- \n";
&testLogin();

## run tests in Wizard.t
print "ok -- Testing Wizard.pm -- \n";
&testWizard();
#
print "ok -- Testing Downloadfile.pm -- \n";
#
## tests inside DownloadFile.t
&testDownloadFile("myfavTestId");
#
## run test in releases.t with release id "myfavTestID" and change pw to "newpassword"
#print "ok -- Testing Releases.pm --\n";
&testReleases( "myfavTestId", "newpassword" );

    
sub bootstrapTestEnvironment {
    
    # grant rwx to docRoot
    system("chmod 0700 $documentRoot");
    
    # delete old sessions
    system("rm -f $sessionDir/*");

    # delete old db files
    system("rm -f $csvPath/config.csv");
    system("rm -f $csvPath/temp.csv");
    system("rm -f $csvPath/codes_for*.csv");

    # delete old upload files
    system("rm -f $uploadPath/*.zip");

    # delete old forwarder dirs
    system("rm -rf $documentRoot/$forwardDir/");

    # delete old weblib dir
    system("rm -rf $documentRoot/$webLibDir");

    # adjust chmod for install.cgi
    system("chown www-data $cgiPath/install.cgi");
    chmod 0544, "$cgiPath/install.cgi";
}
