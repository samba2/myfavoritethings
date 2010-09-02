package MyFav::SubApps::DownloadFile;

use strict;
use CGI::Carp qw ( fatalsToBrowser );
use MyFav::CheckInput;
use MyFav::DB::ReleaseDB;
use MyFav::CheckInput;
use File::Basename;
use File::stat;

use base 'MyFav::Base';

my $inputChecker;
my $configDb;
my $releaseDb;

# overwrite super method to prevent login redirect
sub cgiapp_prerun {
}

sub setup {
	my $self = shift;

	$self->tmpl_path( $self->getTemplatePath );
	$self->start_mode('downloadWelcomeScreen');
	$self->mode_param('rm');

	$self->run_modes(
		'downloadWelcomeScreen' => 'runModeDownloadWelcomeScreen',
		'downloadStartDownload' => 'runModeDownloadStartDownload',
		'streamFile'            => 'runModeStreamFile',
		'rateLimitExceeded' => $self->can('runModeRateLimitExceeded'),
		'AUTOLOAD'              =>  $self->can('runModeDefault')
	);

	my %cgiParams = $self->getCgiParamsHash();
	$inputChecker = MyFav::CheckInput->new(%cgiParams);
	
	$configDb = $self->createConfigDbObject();
	my $rateLimiter = $self->initRateLimiter();

	# protect all oridnary runmodes  by rate limiter
	$rateLimiter->protected_modes(downloadWelcomeScreen => {timeframe => $configDb->getRateLimiterTimeFrame(),
                                          max_hits  => $configDb->getRateLimiterMaxHits()},
                                    downloadStartDownload => {timeframe => $configDb->getRateLimiterTimeFrame(),
                                          max_hits  => $configDb->getRateLimiterMaxHits()},
                                    streamFile => {timeframe => $configDb->getRateLimiterTimeFrame(),
                                          max_hits  => $configDb->getRateLimiterMaxHits()});
}

sub runModeDownloadWelcomeScreen {
	my $self     = shift;
	my $errorMsg = shift;
	my $template;

	# try to present download form
	# die "" = die without a special warning, prevents CGI::Carp warnings 
	eval {
		my $releaseIdHash = $self->getHashedReleaseId() or die "";
		my $releaseId = $self->getSaveReleaseId() or die "";
		if (! $releaseId) {die ""}
		my $releaseName = $configDb->getReleaseName($releaseId) or die "";

		$template = $self->load_tmpl("downloadInputCode.tmpl");
		$template->param( "SCRIPTNAME"   => $self->getCgiScriptName );
		$template->param( "ERRORMESSAGE" => $errorMsg );
		$template->param( "RELEASENAME"  => $releaseName );
		$template->param( "R"            => $releaseIdHash );
	};

	# catch exception, display default page
	if ($@) {
		$template = $self->load_tmpl("downloadWelcomeScreen.tmpl");
		$template->param( "VERSIONID" => $configDb->getVersionId() );
	}

	return $self->renderPage( $template, "pageIsPublic" );
}

sub runModeDownloadStartDownload {
	my $self = shift;
	my $error;
	my $template;

	my $downloadCode  = $self->getDownloadCode();
	my $releaseId = $self->getSaveReleaseId();
	if (! $releaseId) {
		return $self->runModeDownloadWelcomeScreen();
	}

	# create release db object
	$releaseDb = $self->getReleaseDb($releaseId) or die "";

	# download logic
	# start with input check
	my $inputCheckErrors = $inputChecker->checkDownloadCode($downloadCode);

	if ($inputCheckErrors) {
		$self->runModeDownloadWelcomeScreen($inputCheckErrors);
	}
	elsif ( !$releaseDb->codeExists($downloadCode) ) {
		$error = "The code you have entered is not valid.";
		$self->runModeDownloadWelcomeScreen($error);
	}
	elsif ( $releaseDb->codeIsUsed($downloadCode)
		&& !$self->codeIsInsideDownloadTimeFrame($releaseId, $downloadCode) )
	{
		$error = "The code you have entered has expired.";
		$self->runModeDownloadWelcomeScreen($error);
	}
	else {
		$self->displayDownloadAllowedPage();
	}
}

# called via an iframe or a direct link in downloadAllowed.tmpl
sub runModeStreamFile {
	my $self = shift;

	my $downloadCode = $self->getDownloadCode();
	my $releaseId = $self->getSaveReleaseId();
	if (! $releaseId) {
		return $self->runModeDownloadWelcomeScreen();
	}
	
	$releaseDb = $self->getReleaseDb($releaseId);

	# only allow file streaming if code was set to "used" before and
	# if the code is inside the time frame
	if (   $releaseDb->codeIsUsed($downloadCode)
		&& $self->codeIsInsideDownloadTimeFrame($releaseId, $downloadCode) )
	{
		my $zipFilePath = $configDb->getUploadFilePath($releaseId);

		$self->sendFileToBrowser($zipFilePath);
	}
}

sub displayDownloadAllowedPage {
	my $self         = shift;
	my $downloadCode = $self->getDownloadCode();

	my $cgi         = $self->query();
	my $remoteHost  = $cgi->remote_host();
	my $userAgent   = $cgi->user_agent();
	my $currentTime = $self->getCurrentTimeString();

	$releaseDb->updateUsedCode( $downloadCode, $currentTime, $remoteHost,
		$userAgent );

	my $releaseIdHash = $self->getHashedReleaseId();
	# escaping to let the browser deal with special characters
	$releaseIdHash = $self->getEscapedValue($releaseIdHash);
	
	my $template      = $self->load_tmpl("downloadAllowed.tmpl");

	$template->param( "SCRIPTNAME"    => $self->getCgiScriptName );
	$template->param( "RELEASEIDHASH" => $releaseIdHash );
	$template->param( "DOWNLOADCODE"  => $downloadCode );

	return $self->renderPage( $template, "pageIsPublic" );
}


sub getSaveReleaseId {
	my $self = shift;
	my $releaseId;

	eval {
		my $releaseIdHash = $self->getHashedReleaseId() or die "";
		$releaseId = $configDb->getReleaseIdByReleaseHash($releaseIdHash)
		  or die "";
		$configDb->releaseExistsInConfigDb($releaseId) or die "";
	};

	# only return value if no exception took place
	if (! $@) {
		return $releaseId;
	}
}

sub sendFileToBrowser {
	my $self        = shift;
	my $zipFilePath = shift;
	my $zipFileName = basename($zipFilePath);
	my $zipSize     = stat($zipFilePath)->size;

	# do the header ourselfs
	$self->header_type('none');
	print "Content-Type: application/octet-stream\n";
	print "Content-Length: $zipSize\n";
	print "Content-Disposition: attachment; filename=$zipFileName\n\n";
	open( FH, "<$zipFilePath" )
	  || die "Could not open $zipFilePath for reading. Exiting.";
	binmode FH;
	binmode STDOUT;
	local $/ = \10240;    # 10 k blocks
	print while (<FH>);
	close FH;

	return;
}

# the parameter "r" holds the release hash
sub getHashedReleaseId {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();
	return $cgiParams{"r"};
}

sub getDownloadCode {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();
	return $cgiParams{"downloadCode"};
}

1;
