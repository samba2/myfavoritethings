#########################################################
package AnyData::Format::Weblog;
#########################################################
# AnyData driver for "Common Log Format" web log files
# copyright (c) 2000, Jeff Zucker <jeff@vpservices.com>
#########################################################

=head1 NAME

AnyData::Format::Weblog - tiedhash & DBI/SQL access to HTTPD Logs

=head1 SYNOPSIS

 use AnyData;
 my $weblog = adTie( 'Weblog', $filename );
 while (my $hit = each %$weblog) {
    print $hit->{remotehost},"\n" if $hit->{request} =~ /mypage.html/;
 }
 # ... other tied hash operations

 OR

 use DBI
 my $dbh = DBI->connect('dbi:AnyData:');
 $dbh->func('hits','Weblog','access_log','ad_catalog');
 my $hits = $dbh->selectall_arrayref( qq{
     SELECT remotehost FROM hits WHERE request LIKE '%mypage.html%'
 });
 # ... other DBI/SQL read operations

=head1 DESCRIPTION

This is a plug-in format parser for the AnyData and DBD::AnyData modules. You can gain read access to Common Log Format files web server log files (e.g. NCSA or Apache) either through tied hashes or arrays or through SQL database queries.

Fieldnames are taken from the W3 definitions found at

http://www.w3.org/Daemon/User/Config/Logging.html#common-logfile-format

 remotehost
 usernname
 authuser
 date
 request
 status
 bytes

In addition, two extra fields that may be present in extended format logfiles are:

 referer
 client

This module does not currently support writing to weblog files.

Please refer to the documentation for AnyData.pm and DBD::AnyData.pm
for further details.

=head1 AUTHOR & COPYRIGHT

copyright 2000, Jeff Zucker <jeff@vpservices.com>
all rights reserved

=cut


use strict;
use AnyData::Format::Base;
use vars qw( @ISA $DEBUG $VERSION);
@AnyData::Format::Weblog::ISA = qw( AnyData::Format::Base );
$DEBUG = 0;

$VERSION = '0.06';

sub new {
    my $class = shift;
    my $self = shift || {};
    $self->{col_names} =
        'remotehost,username,authuser,date,request,status,bytes,client,referer';
    $self->{record_sep} = "\n";
    $self->{key} = 'datestamp';
    $self->{keep_first_line} = 1;
    return bless $self, $class;
}

sub read_fields {
    print "PARSE RECORD\n" if $DEBUG;
    my $self = shift;
    my $str  = shift || return undef;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return undef unless $str;
    my(@row) = $str =~
        /^(\S*) (\S*) (\S*) \[([^\]]*)\] "(.*)" (\S*) (\S*)\s*(.*)$/;
    return undef unless defined $row[0];
    my($client,$referer) = $row[7] =~ /^(.*) (\S*)$/;
    $client  ||= '';
    $referer ||= '';
    ($row[7],$row[8])=($client,$referer);
    # $row[3] =~ s/\s*-\s*(\S*)$//; # hide GMT offset on datestamp
    return @row
}
1;



