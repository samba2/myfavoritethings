package MyFav::DB::ReleaseDB;

use strict;
use CGI::Carp qw ( fatalsToBrowser );

use base 'MyFav::DB::General';

sub createReleaseDataBase {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();

	$self->writeToDataBase(
"CREATE TABLE $dataBaseName (code TEXT, status TEXT, timeStamp TEXT, remoteHost TEXT, userAgent TEXT )"
	);
}

sub fillReleaseDataBaseWithNewCodes {
	my $self          = shift;
	my $codeCount     = shift;
	my $codeGenerator = new MyFav::RandomNumberGenerator;

	my @codes = $codeGenerator->generateCodes($codeCount);

	foreach my $code (@codes) {
		$self->insertNewCodeRow($code);
	}
}

sub insertNewCodeRow {
	my $self         = shift;
	my $code         = shift;
	my $dataBaseName = $self->getDataBaseName();


	$self->writeToDataBase(
"INSERT INTO $dataBaseName VALUES ('$code', 'unused', '', '', '')"
	);
}

sub codeExists {
	my $self         = shift;
	my $code         = shift;
	my $dataBaseName = $self->getDataBaseName();

	my $result = $self->selectSingleValue(
		"SELECT COUNT(*) FROM $dataBaseName WHERE code='$code'");
	return $result;
}

sub codeIsUsed {
	my $self         = shift;
	my $code         = shift;
	my $dataBaseName = $self->getDataBaseName();

	my $result = $self->selectSingleValue(
		"SELECT COUNT(*) FROM $dataBaseName WHERE code='$code' AND status='used'");
	return $result;
}


sub updateUsedCode {
	my $self        = shift;
	my $code        = shift;
	my $currentTime = shift;
	my $remoteHost  = shift;
	my $userAgent   = shift;

	# remove possible csv delimiter chars
	$userAgent =~ s/,//;
	$userAgent =~ s/;//;

	my $dataBaseName = $self->getDataBaseName();
	$self->writeToDataBase(
"UPDATE $dataBaseName SET status='used', timeStamp='$currentTime', remoteHost='$remoteHost', userAgent='$userAgent' WHERE code='$code'"
	);
}

sub getTimeStamp {
	my $self         = shift;
	my $code         = shift;
	my $dataBaseName = $self->getDataBaseName();

	my $result = $self->selectSingleValue(
		"SELECT timeStamp FROM $dataBaseName WHERE code='$code'");
	return $result;
}

sub getTotalCodeCount {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();

	my $result = $self->selectSingleValue("SELECT COUNT(*) FROM $dataBaseName");
	return $result;
}

sub getUsedCodeCount {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();

	my $result = $self->selectSingleValue("SELECT COUNT(*) FROM $dataBaseName WHERE status='used'");
	if (! $result) {$result=0} # handle empty result
	
	return $result;
}

sub setCodeToUnused {
	my $self        = shift;
	my $code        = shift;

	my $dataBaseName = $self->getDataBaseName();
	$self->writeToDataBase(
"UPDATE $dataBaseName SET status='unused', timeStamp='', remoteHost='', userAgent='' WHERE code='$code'"
	);
}

sub getReleaseAsCsv {
	my $self = shift;
	
	my $dataBaseName = $self->getDataBaseName();
	my $dataBaseHandle = $self->getDataBaseHandle();
	
	my $statementHandle=$dataBaseHandle->prepare("SELECT * FROM $dataBaseName");
	$statementHandle->execute();

	my @result;
	my $tempRow;

	# handle table heading, NAME_lc returns ref to array of field(=column) names	
	foreach (@{ $statementHandle->{NAME_lc} }) {
		$tempRow .= "$_,";
	}
	$tempRow .= "\n";
	push @result, $tempRow;
		
	# handle table data
	while(my $row = $statementHandle->fetchrow_arrayref) {
		$tempRow = "";
		foreach (@$row) { 
			$_ = '' unless defined; # handle NULL value 
			$tempRow .= "$_," 
		} 
		$tempRow .= "\n";
		push @result, $tempRow;
	}
	
	# return the whole bunch
	return @result;
}

sub getAllCodes {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();
	
	my %result = $self->selectHashSimple("SELECT code FROM $dataBaseName");
	return keys %result;
}


# for Download.t test script only
sub getFirstCode {
	my $self         = shift;
	my $dataBaseName = $self->getDataBaseName();

	my $result = $self->selectSingleValue(
		"SELECT code FROM $dataBaseName");
	return $result;
}

1;
