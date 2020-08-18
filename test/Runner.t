#! /usr/bin/perl
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;

# use TestContainerTest;
use InstallTest;
# use InstallOkTest;
# use LoginTest;
# use WizardTest;
# use ReleasesTest;
# use DownloadFileTest;

Test::Class->runtests;