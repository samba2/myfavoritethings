#!/bin/sh
#! -*-perl-*-
# run with the provided perl interpreter.
# some magic inspired from 'perldoc perlrun'
eval 'exec $(realpath ../perl5/bin/perl) -w -x $0'
    if 0;

# TODO how to inject lib path (PERL5LIB is not an option)

use strict;

use lib "../lib/";
use MyFav::SubApps::Install;

my $wizard = MyFav::SubApps::Install->new();
$wizard->run();