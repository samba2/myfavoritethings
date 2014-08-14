package MyFav::DB::TempDB;

use strict;
use CGI::Carp qw ( fatalsToBrowser );  

use base 'MyFav::DB::General';

sub createTempDataBase {
	my $self = shift;
	my $dataBaseName = $self->getDataBaseName();

	$self->writeToDataBase("CREATE TABLE $dataBaseName (keyVal TEXT, dataVal TEXT)");
}

sub insertTempValue {
	my $self = shift;
	my $key = shift;
	my $value = shift;
	my $dataBaseName = $self->getDataBaseName();	

	# handles deletion of old values if browser "back" button is used and data is retransmitted
	$self->writeToDataBase("DELETE FROM $dataBaseName WHERE keyVal='$key'");
	
	$self->writeToDataBase("INSERT INTO $dataBaseName (keyVal, dataVal) VALUES ('$key','$value')");
}

sub cleanTemporaryValues {
	my $self = shift;
	my $dataBaseName = $self->getDataBaseName();
	
	$self->writeToDataBase("DELETE FROM $dataBaseName");
}

sub getTempValue {
	my $self = shift;
	my $key = shift;
	
	my $result = $self->selectSingleValue("SELECT dataVal FROM temp WHERE keyVal='$key'");
	return $result;
}


1;