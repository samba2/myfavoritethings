#! /usr/bin/perl
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;

use TestContainerTest;
 
Test::Class->runtests;