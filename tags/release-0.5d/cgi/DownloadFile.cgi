#!/usr/bin/perl -w

use strict;

use lib "../lib/";
use MyFav::SubApps::DownloadFile;

my $wizard = MyFav::SubApps::DownloadFile->new();
$wizard->run();