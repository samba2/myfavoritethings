package MyFav::SubApps::Wizard;

use strict;
use CGI::Carp qw ( fatalsToBrowser );

use MyFav::CheckInput;
use MyFav::DB::General;
use MyFav::DB::ConfigDB;
use MyFav::DB::ReleaseDB;
use MyFav::DB::TempDB;
use MyFav::RandomNumberGenerator;

use base 'MyFav::Base';

my $tempDb;
my $inputChecker;
my $configDb;

# TODO javascripts als variable in tmpl setzen

sub setup {
	my $self = shift;

	$self->tmpl_path( $self->getTemplatePath );
	$self->start_mode('wizardProjectDetails');
	$self->mode_param('rm');

	$self->run_modes(
		'wizardProjectDetails'    => 'runModeProjectDetails',
		'wizardReleaseDetails'    => 'runModeReleaseDetails',
		'wizardFordwarderDetails' => 'runModeForwarderDetails',
		'wizardUploadFile'        => 'runModeUploadFile',
		'wizardReleaseCreated'    => 'runModeReleaseCreated',
		'AUTOLOAD'                => $self->can('runModeDefault')

	);

	$tempDb = MyFav::DB::TempDB->new(
		"dataBaseName" => "temp",
		"dataBaseDir"  => $self->getDataBaseDir()
	);

	if ( !$tempDb->dataBaseExists() ) {
		$tempDb->createTempDataBase();
	}

	my %cgiParams = $self->getCgiParamsHash();
	$inputChecker = MyFav::CheckInput->new(%cgiParams);

	# create config db object
	$configDb = MyFav::DB::ConfigDB->new(
		"dataBaseName" => "config",
		"dataBaseDir"  => $self->getDataBaseDir()
	);

}

# only first word of release name is repeated
sub runModeProjectDetails {
	my $self     = shift;
	my $errorMsg = shift;

	my $template = $self->setupForm( "wizardProjectDetails.tmpl", $errorMsg );

	$template->param( "RELEASENAME" => $self->getReleaseName );
	$template->param( "RELEASEID"   => $self->getReleaseId );

	return $self->renderPage($template);
}

sub runModeReleaseDetails {
	my $self             = shift;
	my $internalErrorMsg = shift;

# data comes from outside (cgi data from the browser) since $internalErrorMsg is not set
	if ( !$internalErrorMsg ) {
		my $error = $inputChecker->checkWizardReleaseDetails();

		if ($error) {
			return $self->runModeProjectDetails($error);
		}
		else {
			$tempDb->cleanTemporaryValues();
			$tempDb->insertTempValue( "releaseName", $self->getReleaseName );
			$tempDb->insertTempValue( "releaseId",   $self->getReleaseId );
		}
	}

	my $template =
	  $self->setupForm( "wizardNumberOfCodes.tmpl", $internalErrorMsg );

	$template->param( "CODECOUNT" => $self->getCodeCount );

	return $self->renderPage($template);
}

sub runModeForwarderDetails {
	my $self             = shift;
	my $internalErrorMsg = shift;

	if ( !$internalErrorMsg ) {
		my $error = $inputChecker->checkWizardNumberOfCodes();

		if ($error) {
			return $self->runModeReleaseDetails($error);
		}
		else {
			$tempDb->insertTempValue( "codeCount", $self->getCodeCount );
		}
	}

	my $template =
	  $self->setupForm( "wizardForwarderDetails.tmpl", $internalErrorMsg );

    my $randomDirName= $self->getRandomDirName();
	  
	$template->param( "CUSTOMDIR" => $self->getCustomDir() );
	$template->param( "DOWNLOAD_DEF_PATH" => $configDb->getDownloadDefaultPath() );
    $template->param( "RELEASEID" => $tempDb->getTempValue("releaseId"));
    $template->param( "DOWNLOAD_CGI_PATH" => $configDb->getDownloadCgiPath() );
    $template->param( "RANDOM_DIR_NAME" => $randomDirName );
      
	# set default selection to "random string"
	if ( !$self->getForwardButtonState() ) {
		$self->setForwardButtonState('RANDOMSTRINGCHECKED');
	}

	$template->param( $self->getForwardButtonState() => 'checked' );

	return $self->renderPage($template);
}

sub runModeUploadFile {
	my $self             = shift;
	my $internalErrorMsg = shift;

	if ( !$internalErrorMsg ) {

		# input check for forwarder details
		my $forwarderDir    = $configDb->getForwarderDir();
		my $forwarderChoice = $self->getForwarderChoice();

		if ( $forwarderChoice eq "randomString" ) {
			$tempDb->insertTempValue( "releaseForwarderDir", $self->getRandomName() );
		}

		# TODO we internally use "releaseName" as variable for this choice
		# but actually releaseId is used
		elsif ( $forwarderChoice eq "releaseName" ) {
			my $releaseId = $tempDb->getTempValue("releaseId");
			my $error     = $inputChecker->checkWizardForwardDirByReleaseName(
				"$forwarderDir/$releaseId");

			if ($error) {
				$self->setForwardButtonState('RELEASENAMECHECKED');
				return $self->runModeForwarderDetails("$error");
			}
			else {
				$tempDb->insertTempValue( "releaseForwarderDir", "$releaseId" );
			}
		}
		elsif ( $forwarderChoice eq "customString" ) {
			my $customDir = $self->getCustomDir();
			my $error     = $inputChecker->checkWizardCustomForwardDir(
				"$forwarderDir/$customDir");

			if ($error) {
				$self->setForwardButtonState('CUSTOMSTRINGCHECKED');
				return $self->runModeForwarderDetails("$error");
			}
			else {
				$tempDb->insertTempValue( "releaseForwarderDir", "$customDir" );
			}
		}
	}

	my $template =
	  $self->setupForm( "wizardUploadZipFile.tmpl", $internalErrorMsg );

	# feed maximum upload size into template to display warning before upload
	my $formatSize = Number::Bytes::Human->new();
	my $maxAllowedSizeFormated =
	  $formatSize->format( $configDb->getMaximumUploadFileSize() );
	$template->param( "UPLOAD_CHOOSER" => 1 );
	$template->param( "NEXTRUNMODE" => "wizardReleaseCreated" );
	$template->param( "MAXALLOWEDSIZE" => $maxAllowedSizeFormated );

	return $self->renderPage($template);
}

# implement wizardReleaseCreatedWithoutFile
sub runModeReleaseCreated {
	my $self             = shift;
	my $internalErrorMsg = shift;
	my $releasePrefix    = $self->getReleaseDbPrefix();
	my $fileUpload       = $self->getFileUploadedFlag();
	my $template;

	if ( !$internalErrorMsg ) {
        # at this point the file has been uploaded to CGI.pm's temp space.
        # delete upload-status file
        eval {
             my $uploadStatusFileName = $self->getUploadStatusFilePath();
             unlink $uploadStatusFileName;
        };

		if ( $fileUpload eq "true" ) {
			my $error = $inputChecker->checkWizardUploadFile();

			if ($error) {
				return $self->runModeUploadFile($error);
			}
		}

		if ( $fileUpload eq "true" ) {
			$self->uploadFile();
		}
		
		# last steps. try to write forwarder index.html + create release db
		my $releaseName = $tempDb->getTempValue("releaseName");
		my $releaseId   = $tempDb->getTempValue("releaseId");
		my $codeCount   = $tempDb->getTempValue("codeCount");

		my $uploadFilePath = ();
		if ( $fileUpload eq "true" ) {
			$uploadFilePath = $self->getFileDir() . "/" . $self->getFileName();
		}
		else {
			$uploadFilePath = "not_defined";
		}
		my $releaseIdHash = $self->getHashedValue($releaseId);

		# build url like http://xxxx/cgi-bin/DownloadFile.cgi?r=hashedreleasid
		my $releaseCgiUrl =
		    $configDb->getDownloadCgiPath() . "?r="
		  . $self->getEscapedValue($releaseIdHash);

		# build url like http://xxx/DigitalDownload/AXDS/
		my $downloadUrl =
		    $configDb->getDownloadDefaultPath() . "/"
		  . $tempDb->getTempValue("releaseForwarderDir") . "/";

		# build actual file path for forward like
		# /var/www/DigitalDownloads/ABCD
		my $pathIndexHtmlDir =
		    $configDb->getForwarderDir() . "/"
		  . $tempDb->getTempValue("releaseForwarderDir");

		eval {

			# try to write the index.html file containing
			# the forward to the actual DownloadFile.cgi +
			$self->writeForwardHtmlFile( $releaseCgiUrl, $pathIndexHtmlDir );

			# check if url is accessible via the web
			$self->urlAccessible("$downloadUrl")
			  or die "Self check failed: Could not open URL $downloadUrl.";
		};

		if ($@) {

			# do nothing and print error message
			$template =
			  $self->setupForm( "wizardErrorReleaseCreated.tmpl", $@ );
		}
		else {

			# everything is fine
			# create release db object
			my $releaseDb = MyFav::DB::ReleaseDB->new(
				"dataBaseName" => $releasePrefix . "$releaseId",
				"dataBaseDir"  => $self->getDataBaseDir
			);

			my $releaseDbPath =
			    $self->getDataBaseDir() . "/"
			  . $self->getReleaseDbPrefix()
			  . $releaseId . "."
			  . $releaseDb->getDbExtension();

			# fill config db with project details
			$configDb->insertConfigValue( "$releaseId", "releaseId",
				"$releaseId" );
			$configDb->insertConfigValue( "$releaseId", "releaseName",
				"$releaseName" );
			$configDb->insertConfigValue( "$releaseId", "uploadFilePath",
				"$uploadFilePath" );
			$configDb->insertConfigValue( "$releaseId", "releaseDbPath",
				"$releaseDbPath" );
			$configDb->insertConfigValue( "$releaseId", "releaseIdHash",
				"$releaseIdHash" );
			$configDb->insertConfigValue( "$releaseId", "releaseCgiUrl",
				"$releaseCgiUrl" );
			$configDb->insertConfigValue( "$releaseId", "downloadUrl",
				"$downloadUrl" );
			$configDb->insertConfigValue( "$releaseId", "pathIndexHtmlDir",
				"$pathIndexHtmlDir" );

			if ($fileUpload eq "true") {
                $configDb->insertConfigValue( "$releaseId", "status",
                    "Online" );
			}
			else {
                $configDb->insertConfigValue( "$releaseId", "status",
                    "File missing" );
			}	
				
				

			# create release db + writeout codes
			$releaseDb->createReleaseDataBase();
			$releaseDb->fillReleaseDataBaseWithNewCodes($codeCount);
			$template = $self->load_tmpl("wizardReleaseCreated.tmpl");
		}

		# delete temp values anyway
		$tempDb->cleanTemporaryValues();

		return $self->renderPage($template);
	}
}

# runs after run mode
sub cgiapp_postrun {
	my $self       = shift;
	my $output_ref = shift;

}

sub writeForwardHtmlFile {
	my $self             = shift;
	my $releaseCgiUrl    = shift;
	my $pathIndexHtmlDir = shift;

	my $releaseId     = $tempDb->getTempValue("releaseId");
	my $releaseIdHash = $self->getHashedValue("$releaseId");

	mkdir( "$pathIndexHtmlDir", 0755 )
	  or die "Could not create directory $pathIndexHtmlDir";

	# prepare template of index.html with data and write result out to disk
	my $template = $self->load_tmpl("forwardIndexFile.tmpl");
	$template->param( "RELEASECGIURL" => $releaseCgiUrl );
	open( FH, ">$pathIndexHtmlDir/index.html" )
	  or die
	  "Could not open file $pathIndexHtmlDir/index.html for write access";
	$template->output( print_to => *FH );
	close FH;
}

sub getReleaseName {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();
	return $cgiParams{"releaseName"};
}

sub getReleaseId {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();
	return $cgiParams{"releaseId"};
}

sub getCodeCount {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();
	return $cgiParams{"codeCount"};
}

sub getForwarderChoice {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();

	# in case radio box has no default selection (should not happen)
	# choose random string as default. avoids comparision against empty string
	if ( !$cgiParams{"forwarder"} ) {
		return "randomString";
	}
	else {
		return $cgiParams{"forwarder"};
	}
}

sub getCustomDir {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();
	return $cgiParams{"customDir"};
}

sub getForwardButtonState {
	my $self = shift;
	return $self->param('forwardButtonState');
}

sub getRandomName {
    my $self      = shift;
    my %cgiParams = $self->getCgiParamsHash();
    return $cgiParams{"randomDirName"};
}

sub setForwardButtonState {
	my $self           = shift;
	my $selectedButton = shift;

	$self->param( 'forwardButtonState', $selectedButton );
}

sub getFileUploadedFlag {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();
	return $cgiParams{'fileUploaded'};
}

sub getRandomDirName {
    my $self         = shift;
    my $forwarderDir = $configDb->getForwarderDir();

    my $randomGen = MyFav::RandomNumberGenerator->new();
    my $randomDirName;

    do {
        $randomDirName = $randomGen->generateSingleCode(4);
    } until ( !$self->directoryExists("$forwarderDir/$randomDirName") );
    
    return ( $randomDirName);
}


1;

