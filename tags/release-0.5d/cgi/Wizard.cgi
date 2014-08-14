#!/usr/bin/perl -w

use strict;

use lib "../lib/";
use MyFav::SubApps::Wizard;

my $wizard = MyFav::SubApps::Wizard->new();
$wizard->run();






