#!/bin/sh
#! -*-perl-*-
# run with the provided perl interpreter.
# some magic inspired from 'perldoc perlrun'
eval 'exec $(realpath ../perl5/bin/perl) -w -x $0'
   if 0;

BEGIN {push @INC , 
    '../perl5/lib/provided_version/', 
    '../perl5/lib/provided_version/x86_64-linux/', 
    '../perl5/lib/site_perl/provided_version/', 
    '../perl5/lib/site_perl/provided_version/x86_64-linux/', 
    '../lib/'}

use strict;
use MyFav::SubApps::Login;

my $wizard = MyFav::SubApps::Login->new();
$wizard->run();