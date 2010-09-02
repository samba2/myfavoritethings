#!/usr/bin/perl -w

use strict;

use lib "../lib/";
use MyFav::SubApps::Login;

my $wizard = MyFav::SubApps::Login->new();
$wizard->run();