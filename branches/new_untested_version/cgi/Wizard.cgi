#!/usr/bin/perl -w

use strict;

use lib "../lib/";
use CGI;
use MyFav::SubApps::Wizard;
use MyFav::Base;

# create cgi object with upload hook 
my $cgi =  CGI->new(\&MyFav::Base::uploadCgiHook);

my $wizard = MyFav::SubApps::Wizard->new(QUERY => $cgi);
$wizard->run();






