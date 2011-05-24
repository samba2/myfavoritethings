package MyFav::DB::General;

use strict;
use CGI::Carp qw ( fatalsToBrowser );  

# use always the pure perl version of dbi.pm
BEGIN { $ENV{DBI_PUREPERL}=2 }
use DBI;
use DBD::AnyData;
use MyFav::RandomNumberGenerator;

# csv support is currently hardcoded. 
my $extension = "csv";

sub new {
	my $class = shift;
	
	croak "Illegal parameter list has odd number of values" 
        if @_ % 2;
	
	my (%params) = @_;
 
	bless {"dataBaseName" => $params{"dataBaseName"},
		   "dataBaseDir" => $params{"dataBaseDir"}
    }, $class;
}

sub dataBaseExists {
	my $self = shift; 
	my $filePath = $self->getFilePath();
	
	if (-r $filePath) {	return 1}
	else {return 0}
}

sub selectSingleValue {
	my $self = shift;
	my $statement = shift;
	my $dbHandle = $self->getDataBaseHandle();
	
	my @dbResult = $dbHandle->selectrow_array($statement);
	return $dbResult[0];
}

# "select key,value from table" returns a key => value hash
sub selectHashSimple {
	my $self = shift;
	my $statement = shift;
	my $dbHandle = $self->getDataBaseHandle();
	my %resultHash;
	my @dbResult;

	my $sth = $dbHandle->prepare($statement);
	$sth->execute();
	
	while (@dbResult = $sth->fetchrow_array)  {
		$resultHash{$dbResult[0]} = $dbResult[1];
	}
	
	return %resultHash;
}

sub getFilePath {
	my $self = shift;

	my $filePath =
	    $self->getDataBaseDir() . "/"
	  . $self->getDataBaseNameNormalCase() . "."
	  . $extension;
	return ($filePath);
}


sub getDataBaseHandle {
	my $self = shift;
	my $filePath  = $self->getFilePath();
	my $dataBaseName = $self->getDataBaseName();

	my $dbHandle = DBI->connect('dbi:AnyData(RaiseError=>1):');
    $dbHandle->func($dataBaseName, uc($extension), $filePath ,'ad_catalog');
    
    return $dbHandle;	
}


sub writeToDataBase {
	my $self = shift;
	my $sqlStatement = shift;
	my $dbHandle = $self->getDataBaseHandle();
	
	$dbHandle->do("$sqlStatement");
}

sub setDataBaseName {
	my $self = shift;
	$self->{dataBaseName} = shift;
}

# this is the database name for all SELECT * FROM dataBaseName queries
# DBI::PurePerl had problems with mixed case database names so we
# put it lower case here
sub getDataBaseName {
	my $self = shift;
	return lc($self->{dataBaseName});
}

# problem above introduced this method which is only used
# to build a file path to the csv file with db name in normal case
sub getDataBaseNameNormalCase {
	my $self = shift;
	return $self->{dataBaseName};
}


sub setDataBaseDir {
	my $self = shift;
	$self->{dataBaseDir} = shift;
}

# returns only instance value of db
sub getDataBaseDir {
	my $self = shift;
	return $self->{dataBaseDir};
}

sub getDbExtension {
	return $extension;
}


1;



