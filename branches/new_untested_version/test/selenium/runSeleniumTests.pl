#!/usr/bin/perl -w

use strict;
use lib "../../lib/";

use warnings;
use Time::HiRes qw(sleep);
use Test::WWW::Selenium;
use Test::More "no_plan";
use Test::Exception;

use test50_setStatusOnlineOffline;
use test51_statusFileMissing;
use test52_downloadExpired;

my $basePath = "/home/ubuntu/workspace/myfav3/myfavoritethings";

our $sel = Test::WWW::Selenium->new( host => "localhost", 
                                    port => 4444, 
                                    browser => "*chrome", 
                                    browser_url => "http://myfav.org/cgi-bin/cgi/Releases.cgi" );

our $uploadFilePath = "$basePath/test/selenium/wizardAddFileTest.zip";
our $configDbDir = "$basePath/data";

### Run Tests ###

# create release
# set release offline
# set release online
# delete release
print "\n";
print "Start test50_setStatusOnlineOffline\n";
test50_setStatusOnlineOffline::runTests();

# create release with "upload later"
# release details contain "File missing" + "Hasnt been uploaded"
# delete + logout
print "\n";
print "Start test51_statusFileMissing\n";
test51_statusFileMissing::runTests();

# create release
# change release expiry date to 2031
# check that download page is working "Thanks for..."
# modify Release-DB, set expiry date to year 2010
# re-check download page, contains now "release has expired"
# delete release
print "\n";
print "Start test52_downloadExpired\n";
test52_downloadExpired::runTests();

