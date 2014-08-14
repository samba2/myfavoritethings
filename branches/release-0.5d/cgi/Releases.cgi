#!/usr/bin/perl -w

use strict;
use lib "../lib/";
use MyFav::SubApps::Releases;

my $wizard = MyFav::SubApps::Releases->new();
$wizard->run();

