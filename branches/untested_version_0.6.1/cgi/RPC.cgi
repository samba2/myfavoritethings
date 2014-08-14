#!/usr/bin/perl -w

use strict;

use lib "../lib/";
use MyFav::SubApps::RPC; 

my $rpc = MyFav::SubApps::RPC->new();
$rpc->run();