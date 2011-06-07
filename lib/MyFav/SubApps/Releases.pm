package MyFav::SubApps::Releases;

use strict;
use MyFav::DB::ConfigDB;
use MyFav::DB::ReleaseDB;
use MyFav::CheckInput;
use MyFav::PdfGenerator;
use CGI::Carp qw ( fatalsToBrowser );
use File::stat;
use File::Path qw(rmtree);
use Number::Bytes::Human qw(format_bytes);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;

use base 'MyFav::Base';

my $configDb;

sub setup {
	my $self = shift;

	# init config db class var
	my $configDb = $self->createConfigDbObject();
	$self->setConfigDb($configDb);

	$self->tmpl_path( $self->getTemplatePath );
	$self->start_mode('mainStatusScreen');
	$self->mode_param('rm');
	$self->run_modes(
		'mainStatusScreen'      => 'runModeMainStatusScreen',
		'modifyFile'            => 'runModeModifyFile',
		'processModifyFile'     => 'runModeProcessModifyFile',
		'deleteRelease'         => 'runModeDeleteRelease',
		'deleteReleaseFinal'    => 'runModeDeleteReleaseFinal',
		'changePassword'        => 'runModeChangePassword',
		'processPasswordChange' => 'runModeProcessPasswordChange',
		'checkCodeStatus'       => 'runModeCheckCodeStatus',
		'processCodeStatus'     => 'runModeProcessCodeStatus',
		'finishCodeStatus'      => 'runModeFinishCodeStatus',
		'exportToCsv'           => 'runModeExportToCsv',
		'exportToPdf'           => 'runModeExportToPdf',
		'logout'                => 'runModeLogout',
		'AUTOLOAD'              => $self->can('runModeDefault')
	);
}

sub runModeMainStatusScreen {
	my $self = shift;

	my $configDb  = $self->getConfigDb();
	my $releaseId = $self->getReleaseId();

	# prevent warnings in server log, so better set it to zero size
	if ( !$releaseId ) { $releaseId = "" }

	my $template = $self->load_tmpl("releasesStatusPage.tmpl");

	my %releases         = $configDb->getListOfAllReleaseNames();
	my @sortedReleaseIds = $self->sortHashByValue(%releases);

	# only execute if there are releases at all
	if (@sortedReleaseIds) {
		my @loop;
		foreach my $releaseIdHash (@sortedReleaseIds) {
			my %row = (
				"RELEASEIDHASH" => $releaseIdHash,
				"RELEASENAME"   => $releases{$releaseIdHash}
			);

			# template LOOP expects array of hashrefs to iterate
			push( @loop, \%row );
		}
		$template->param( "RELEASENAMELOOP" => \@loop );
		$template->param( "SCRIPTNAME"      => $self->getCgiScriptName );
	}

	if ( $configDb->releaseExistsInConfigDb($releaseId) ) {
				
		$template->param( "RELEASEID" => $releaseId );
		$template->param(
			"RELEASENAME" => $configDb->getReleaseName($releaseId) );
		$template->param(
			"DOWNLOADURL" => $configDb->getDownloadUrl($releaseId) );
		$template->param(
			"RELEASECGIURL" => $configDb->getReleaseCgiUrl($releaseId) );
		$template->param(
			"RELEASEDBPATH" => $configDb->getReleaseDbPath($releaseId) );
        $template->param(
            "STATUS" => $configDb->getStatus($releaseId) );

		my $uploadFile = $configDb->getUploadFilePath($releaseId);
		
		# test if file has not been uploaded yet
		if ( $self->fileExists($uploadFile) ) {

		   # auto converts "stat" byte count into human readable format (M,k...)
			my $formatSize = Number::Bytes::Human->new();
			my $size       = $formatSize->format( stat($uploadFile)->size );

			$template->param( "UPLOADFILEPATH" => $uploadFile );
			$template->param( "UPLOADFILESIZE" => $size );
		}

		my $releaseDb = $self->getReleaseDb($releaseId);

		$template->param( "USEDCODES"  => $releaseDb->getUsedCodeCount() );
		$template->param( "TOTALCODES" => $releaseDb->getTotalCodeCount() );
	}

	return $self->renderPage($template);
}


sub runModeModifyFile {
    my $self             = shift;
    my $internalErrorMsg = shift;
    my $releaseId  = $self->getReleaseId();

    my $template =
      $self->setupForm( "wizardUploadZipFile.tmpl", $internalErrorMsg );
    
    # feed maximum upload size into template to display warning before upload
    my $formatSize = Number::Bytes::Human->new();
    my $maxAllowedSizeFormated =
      $formatSize->format( $configDb->getMaximumUploadFileSize() );
    
    $template->param( "MAXALLOWEDSIZE" => $maxAllowedSizeFormated );  
    $template->param( "SCRIPTNAME" => $self->getCgiScriptName );
    $template->param( "RELEASEID" => $releaseId );
    $template->param( "NEXTRUNMODE" => "processModifyFile" );

    return $self->renderPage($template);
}


sub runModeProcessModifyFile {
	my $self = shift;
    my $releaseId = $self->getReleaseId();

	my $inputChecker = $self->getInputChecker();
	my $error        = $inputChecker->checkWizardUploadFile();

	if ($error) {
		return $self->runModeModifyFile($error);
	}
	
	my $configDb = $self->getConfigDb();
	my $currentUploadFilePath = $configDb->getUploadFilePath($releaseId);

    # to replace the file, delete the old one first
    if ($currentUploadFilePath ne "not_defined") {
    	unlink $currentUploadFilePath;
    }

	$self->uploadFile();
	my $uploadFilePath = $self->getFileDir() . "/" . $self->getFileName();
	$configDb->updateUploadFilePath($releaseId, $uploadFilePath);
	$configDb->updateStatus($releaseId, "Online");
	
	return $self->runModeMainStatusScreen();
}


sub runModeDeleteRelease {
	my $self = shift;

	my $configDb  = $self->getConfigDb();
	my $releaseId = $self->getReleaseId();

	my $releaseName = $configDb->getReleaseName($releaseId);
	my $template    = $self->load_tmpl("releasesDeleteRelease.tmpl");
	$template->param( "SCRIPTNAME"  => $self->getCgiScriptName );
	$template->param( "RELEASENAME" => "$releaseName" );
	$template->param( "RELEASEID"   => "$releaseId" );

	return $self->renderPage($template);
}

sub runModeDeleteReleaseFinal {
	my $self = shift;

	my $configDb  = $self->getConfigDb();
	my $releaseId = $self->getReleaseId();

	my $releaseName = $configDb->getReleaseName($releaseId);
	my $template    = $self->load_tmpl("releasesDeleteReleaseFinal.tmpl");
	$template->param( "RELEASENAME" => "$releaseName" );

	my $pathIndexHtmlDir = $configDb->getPathIndexHtmlDir($releaseId);
	my $releaseDbPath    = $configDb->getReleaseDbPath($releaseId);

	my $uploadFilePath = $configDb->getUploadFilePath($releaseId);

	eval {
		if ( $configDb->releaseExistsInConfigDb($releaseId) )
		{
			$configDb->deleteRelease($releaseId);
			rmtree("$pathIndexHtmlDir")
			  or die "Could not delete '$pathIndexHtmlDir'.";
			unlink("$releaseDbPath") or die "Could not delete $releaseDbPath";

			# in case none finished project is deleted
			if ( $self->fileExists($uploadFilePath) ) {
				unlink($uploadFilePath)
				  or die "Could not delete '$uploadFilePath'.";
			}
		}
		else {
			die "Release does not exist in database!";
		}
	};

	if ($@) {
		$template->param( "ERROR" => "$@" );
	}
	return $self->renderPage($template);
}

sub runModeChangePassword {
	my $self     = shift;
	my $errorMsg = shift;

	my $template = $self->load_tmpl("releasesChangePassword.tmpl");

	if ($errorMsg) {
		$template->param( "ERRORMESSAGE" => "$errorMsg" );
	}
	$template->param( "SCRIPTNAME" => $self->getCgiScriptName );

	return $self->renderPage($template);
}

sub runModeProcessPasswordChange {
	my $self = shift;

	my $configDb     = $self->getConfigDb();
	my $inputChecker = $self->getInputChecker();
	my $error        = $inputChecker->checkGeneralPasswordChange();

	# run additional check against old password field
	if ( !$error ) {
		$error = $inputChecker->checkChangeOldPassword();
	}

	if ($error) {
		return $self->runModeChangePassword($error);
	}
	else {
		my $newPassword = $self->getNewPassword();
		$newPassword = $self->getHashedValue($newPassword);

		$configDb->updatePassword($newPassword);
		my $template = $self->load_tmpl("releasesPasswordChanged.tmpl");
		return $self->renderPage($template);
	}
}

sub runModeCheckCodeStatus {
	my $self  = shift;
	my $error = shift;

	my $releaseId = $self->getReleaseId();

	my $template = $self->setupForm( "releasesCheckCodeStatus.tmpl", $error );
	$template->param( "RELEASEID" => "$releaseId" );
	return $self->renderPage($template);
}

# print code info
sub runModeProcessCodeStatus {
	my $self         = shift;
	my $releaseId    = $self->getReleaseId();
	my $downloadCode = $self->getDownloadCode();

	my $inputChecker = $self->getInputChecker();
	my $inputError   = $inputChecker->checkDownloadCode();

	my $releaseDb  = $self->getReleaseDb($releaseId);
	my $codeExists = $releaseDb->codeExists($downloadCode);

	# code had invalid format
	if ($inputError) {
		return $self->runModeCheckCodeStatus($inputError);
	}
	elsif ( !$codeExists ) {
		return $self->runModeCheckCodeStatus(
			"The code '$downloadCode' is not existing.");
	}

	my $template = $self->load_tmpl("releasesProcessCodeStatus.tmpl");
	$template->param( "DOWNlOADCODE" => $downloadCode );
	$template->param( "RELEASEID"    => $releaseId );

	if ( !$releaseDb->codeIsUsed($downloadCode) ) {
		$template->param( "CODENOTUSED" => "1" );
	}
	elsif ( $self->codeIsInsideDownloadTimeFrame( $releaseId, $downloadCode ) )
	{
		$template->param( "CODESTATUS" =>
			  "The code was used and is still inside the download frame." );
	}
	else {
		$template->param( "CODESTATUS" => "The code has expired." );
	}
	return $self->renderPage($template);
}

# perform code reset
sub runModeFinishCodeStatus {
	my $self         = shift;
	my $releaseId    = $self->getReleaseId();
	my $downloadCode = $self->getDownloadCode();

	my $releaseDb = $self->getReleaseDb($releaseId);

	# reset code to unused
	$releaseDb->setCodeToUnused($downloadCode);

	my $template = $self->load_tmpl("releasesFinishCodeStatus.tmpl");

	if ( $releaseDb->codeIsUsed($downloadCode) ) {
		$template->param( "ERROR" => "1" );
	}
	return $self->renderPage($template);
}

sub runModeExportToCsv {
	my $self = shift;

	my $releaseId = $self->getReleaseId();

	my $releaseDb = $self->getReleaseDb($releaseId);

	$self->setupStreamingHeader("$releaseId.csv");

	my @exportData = $releaseDb->getReleaseAsCsv();

	foreach my $row (@exportData) {
		print STDOUT $row;
	}

}

sub runModeExportToPdf {
	my $self = shift;

	my $releaseId = $self->getReleaseId();

	$self->setupStreamingHeader("${releaseId}.pdf");

	my $testPdf = MyFav::PdfGenerator->new( size => 'A4', layout => 'Default' );
	$testPdf->createPdf("$releaseId");
}

sub runModeLogout {
	my $self = shift;

	$self->session->clear('~logged-in');

	return $self->redirect( $self->getCgiScriptName );
}

sub getNewPassword {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();
	return $cgiParams{"newPassword1"};
}

sub setupStreamingHeader {
	my $self     = shift;
	my $fileName = shift;

	# this is a hack. i tried to use $self->header_add
	# but it would always attach the header after I had finished streaming
	# so now I create the header myself.
	$self->header_type('none');
	print "Content-Type: application/octet-stream\n";
	print "Content-Disposition: attachment; filename=$fileName\n\n";
	binmode STDOUT;
}

sub getConfigDb {
	return $configDb;
}

sub setConfigDb {
	my $self  = shift;
	my $value = shift;

	$configDb = $value;
}

sub getReleaseId {
	my $self = shift;

	my $cgi = $self->query();
	return $cgi->param("releaseId");
}

sub getDownloadCode {
	my $self = shift;

	my $cgi = $self->query();
	return $cgi->param("downloadCode");
}

sub getFileModificationType {
    my $self = shift;

    my $cgi = $self->query();
    return $cgi->param("modType");
}

sub getInputChecker {
	my $self = shift;

	my %cgiParams = $self->getCgiParamsHash();
	return MyFav::CheckInput->new(%cgiParams);
}

1;
