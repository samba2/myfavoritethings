#!/usr/local/apache2/cgi-bin/MyFavoriteThings/perl5/bin/perl -w

####!/usr/bin/perl -w
# TODO how to inject perl path and lib path (PERL5LIB is not an option)

use strict;

use lib "../lib/";
use MyFav::SubApps::Install;

my $wizard = MyFav::SubApps::Install->new();
$wizard->run();