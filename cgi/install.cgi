#!/bin/sh
#! -*-perl-*-
# run with the provided perl interpreter.
# some magic inspired from 'perldoc perlrun'
eval 'exec $(realpath ../perl5/bin/perl) \
    -I ../perl5/lib/provided_version/ \
    -I ../perl5/lib/provided_version/x86_64-linux/ \
    -I ../perl5/lib/site_perl/provided_version/ \
    -I ../perl5/lib/site_perl/provided_version/x86_64-linux/ \
    -I ../lib/ \
    -w -x $0'
   if 0;

use strict;
use MyFav::SubApps::Install;

my $wizard = MyFav::SubApps::Install->new();
$wizard->run();