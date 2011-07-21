package MyFav::CheckInput;

use strict;
use CGI::Carp qw ( fatalsToBrowser );  
use Time::Local;

use MyFav::DB::ConfigDB;
use MyFav::Base;

use Number::Bytes::Human qw(format_bytes);

my $textAllowedCharacters =
'The following characters are accepted: a-z, A-Z, 0-9, whitespace, _ . -';

my $textAllowedPasswordChars =
'The following characters are accepted: a-z, A-Z, 0-9, _ - . ! " $ % &';

my $textAllowedDirectoryChars =
'The following characters are accepted: a-z, A-Z, 0-9, -';



my $configDb;
my $baseClass;

sub new {
	my $class = shift;

	croak "Illegal parameter list has odd number of values"
	  if @_ % 2;

	my (%params) = @_;

	# prepare everything to access config db
	$baseClass = MyFav::Base->new();
	my $dataBaseDir = $baseClass->getDataBaseDir();
	$configDb = MyFav::DB::ConfigDB->new(
		"dataBaseName" => "config",
		"dataBaseDir"  => $dataBaseDir
	);

	bless {%params}, $class;
}

sub checkWizardReleaseDetails {
	my $self              = shift;
	my $releaseName       = $self->getReleaseName();
	my $releaseId         = $self->getReleaseId();
	my $releaseNameLength = $configDb->getReleaseNameLength();
	my $releaseIdLength   = $configDb->getReleaseIdLength();

	my $error;

	# checks for release name...
	if ( !$releaseName ) {
		$error = "You must supply a release name.";
	}
	elsif ( length($releaseName) > $releaseNameLength ) {
		$error = sprintf(
"The release name is too long. To maximum allowed size is %s characters.",
			$releaseNameLength );
	}
	elsif ( !$self->hasValidCharacters($releaseName) ) {
		$error = sprintf( "The release name contains unallowed characters. %s",
			$textAllowedCharacters );
	}
	elsif ( $self->startsWithWhiteSpace($releaseName) ) {
		$error = "The release name should not start or end with a whitespace.";
	}

	# ...followed by checks for release ID
	elsif ( !$releaseId ) {
		$error = "You must supply a release ID.";
	}
	elsif ( length($releaseId) > $releaseIdLength ) {
		$error = sprintf(
"The release ID is too long. To maximum allowed size is %s characters.",
			$releaseIdLength );
	}
	elsif ( !$self->hasValidCharacters($releaseId) ) {
		$error = sprintf( "The release ID contains unallowed characters. %s",
			$textAllowedCharacters );
	}
	elsif ( $self->containsWhiteSpace($releaseId) ) {
		$error = "The release ID is not allowed to contain any whitespace.";
	}
	
	elsif ( $configDb->releaseExistsInConfigDb($releaseId)) {
		my $releaseName = $configDb->getReleaseName($releaseId);
		$error = "The release ID '$releaseId' is already used by the release '$releaseName'. Either delete the entire release or choose a different release ID.";
	}
	return $error;
}

sub checkWizardNumberOfCodes {
	my $self            = shift;
	my $codeCount       = $self->getCodeCount();
	my $codeCountLength = $configDb->getCodeCountLength();
	my $error;

	if ( !$self->isNumeric($codeCount) ) {
		$error = "You have to enter a number.";
	}
	elsif ( length($codeCount) > $codeCountLength ) {
		$error = sprintf(
"The number of codes is too long. To maximum allowed length is %s numbers.",
			$codeCountLength );
	}
	return $error;
}

sub checkWizardForwardDirByReleaseName {
	my $self            = shift;
	my $forwarderPath = shift;	
	my $error;
	
	if ($baseClass->directoryExists($forwarderPath)) {
		$error = sprintf("There is already a forward directory with that name")	
	}
	return $error;
}


sub checkWizardCustomForwardDir {
	my $self            = shift;
	my $forwarderPath = shift;	
	my $dirName = $self->getCustomForwardDir();
	my $error;
	
	if ($self->containsWhiteSpace($dirName)) {
		$error = "The custom directory is not allowed to contain any whitespace.";
	}
	elsif (! $self->isValidDirectoryName($dirName)) {
		$error = sprintf( "The directory name contains invalid characters. %s",
			$textAllowedDirectoryChars );
	}
	elsif ($baseClass->directoryExists($forwarderPath)) {
		$error = sprintf("There is already a forward directory with that name")	
	}
	return $error;
}

sub checkWizardUploadFile {
	my $self     = shift;
    
	my $fileName = $self->getFileName();
	my $error;
	
	my $uploadFile  = $baseClass->getFileDir . "/" . $fileName;
		
	my $contentLength = $baseClass->getCgiContentLength();

	my $maximumUploadFileSize = $configDb->getMaximumUploadFileSize();

	# max size check is performed AFTER upload. if this is too inconvinient uploading needs to
	# be replaced by a flash/ java applet which is also able to handle client side size checking
	my $formatSize = Number::Bytes::Human->new();
	my $maxAllowedSizeFormated  = $formatSize->format( $maximumUploadFileSize );
	my $contentLengthFormated = $formatSize->format( $contentLength );

	if ( !$self->hasValidCharacters($fileName) ) {
		$error = sprintf( "The filename contains invalid characters. %s",
			$textAllowedCharacters );
	}
	elsif ($contentLength > $maximumUploadFileSize) {
		$error = "The file you have uploaded exeeds the maximum of $maxAllowedSizeFormated allowed. Your file size is $contentLengthFormated.";
	}
    elsif ( $baseClass->fileExists($uploadFile)) {
        $error = sprintf("The file '%s' is already existing on the server. Please rename your upload file.", $uploadFile);
	}
	
	return $error;
}

sub checkGeneralPasswordChange {
	my $self     = shift;
	my $minPasswordLength = 6;
	my $maxPasswordLength = 20;
	my $newPassword1 = $self->getNewPassword1();
	my $newPassword2 = $self->getNewPassword2();
	my $error;

	if (! $newPassword1 or ! $newPassword2) {
		$error = "You have to fill out all password fields.";
	}
	elsif (length($newPassword1) < $minPasswordLength) {
		$error = "The new password needs to be at least $minPasswordLength characters.";
	}
	elsif (length($newPassword1) > $maxPasswordLength) {
		$error = "The new password needs to be $maxPasswordLength characters at maximum.";
	}	
		
	elsif ($newPassword1 ne $newPassword2) {
		$error = "The new password was not entered two times identical.";
	}
	elsif ($self->containsWhiteSpace($newPassword1)) {
		$error =  "The new password is not allowed to contain whitespaces.";
	}
	elsif (!$self->isValidPasswordString($newPassword1)) {
		$error =  "The new password contains invalid characters. $textAllowedPasswordChars";
	}
	
	return $error;  
}

sub checkChangeOldPassword {
	my $self     = shift;
	my $oldPassword = $self->getOldPassword();
	my $newPassword1 = $self->getNewPassword1();
	my $newPassword2 = $self->getNewPassword2();
	my $error;

	if (! $oldPassword) {
		$error = "Please enter your old password.";
	}
	elsif ($oldPassword eq $newPassword1) {
		$error = "The old and the new password are not allowed to be identical.";	
	}
	
	return $error;
}


sub checkLoginPassword {
	my $self = shift;
	my $loginPasswordMaxLength = 20;
	my $error;
	
	my $loginPassword = $self->getLoginPassword();
	my $adminPassword = $configDb->getAdminPassword();
	# get the length before we hash
	my $loginPasswordLength = length($loginPassword);
	
	# hash the password entered, need to use method of the base class
	my $baseClass = MyFav::Base->new();
	$loginPassword = $baseClass->getHashedValue($loginPassword);
	
	if ( $loginPasswordLength > $loginPasswordMaxLength) {
		$error = "The password you have entered is too long.";
	}
	elsif ($loginPassword ne $adminPassword) {
		$error = "Password was not correct";
	}
	
	return $error;
}	

sub checkDownloadCode {
	my $self = shift;
	my $downloadCodeMaxLength = 20;
	my $error;
	
	my $downloadCode = $self->getDownloadCode();
	
	if (length($downloadCode) > $downloadCodeMaxLength) {
		$error = "The code you have entered is too long."; 
	}
	elsif (! $self->hasValidCharacters($downloadCode)) {
		$error = "The code contains invalid characters";
	}
	
	return $error;
}

sub hasValidCharacters {
	my $self       = shift;
	my $testString = shift;

	if ( $testString =~ m/\A(\w|\s|-|\.)+\Z/ig ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub isValidPasswordString {
	my $self       = shift;
	my $testString = shift;

	if ( $testString =~ m/\A(\w|-|\.|\!|\"|\$|\%|\&)+\Z/ig ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub isValidDirectoryName {
	my $self       = shift;
	my $testString = shift;

	if ( $testString =~ m/\A(\w|-)+\Z/ig ) {
		return 1;
	}
	else {
		return 0;
	}
}


sub containsWhiteSpace {
	my $self       = shift;
	my $testString = shift;

	if ( $testString =~ m/\s+/ig ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub startsWithWhiteSpace {
	my $self       = shift;
	my $testString = shift;

	if ( $testString =~ m/(\A\s)|(\s\Z)/ig ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub isNumeric {
	my $self       = shift;
	my $testNumber = shift;

	if ( $testNumber =~ m/\A\d+\Z/ig ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub getReleaseName {
	my $self = shift;
	return $self->{releaseName};
}

sub getReleaseId {
	my $self = shift;
	return $self->{releaseId};
}

sub getCodeCount {
	my $self = shift;
	return $self->{codeCount};
}

sub getFileName {
	my $self = shift;
	return $self->{fileName};
}

sub getCustomForwardDir {
	my $self = shift;
	return $self->{customDir};
}

sub getOldPassword {
	my $self = shift;
	return $self->{oldPassword};
}

sub getNewPassword1 {
	my $self = shift;
	return $self->{newPassword1};
}

sub getNewPassword2 {
	my $self = shift;
	return $self->{newPassword2};
}

sub getLoginPassword {
	my $self = shift;
	return $self->{loginPassword};
}

sub getDownloadCode {
	my $self = shift;
	return $self->{downloadCode};
}



1;
