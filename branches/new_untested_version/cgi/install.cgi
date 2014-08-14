#!/usr/bin/perl -w

use strict;

use lib "../lib/";
use MyFav::SubApps::Install;

my $wizard = MyFav::SubApps::Install->new();
$wizard->run();