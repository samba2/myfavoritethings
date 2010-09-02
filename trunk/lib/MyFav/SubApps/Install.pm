package MyFav::SubApps::Install;

use strict;
use MyFav::DB::ConfigDB;
use MyFav::CheckInput;
use CGI::Carp qw ( fatalsToBrowser );
use File::Path qw ( mkpath );
use File::Basename;
use File::Copy::Recursive qw ( dircopy );
use CGI::Application::Plugin::Redirect;

use base 'MyFav::Base';

# make some suggestions for the forwarder dir
my %forwardDirSuggestions = (
	1 => "downloads",
	2 => "music",
	3 => "service",
	4 => "getmusic",
	5 => "yourmusic",
	6 => "myfav",
	7 => "qayx"
);


# overwrite method from MyFav::Base
sub cgiapp_prerun { }

sub setup {
	my $self = shift;

	$self->tmpl_path( $self->getTemplatePath );

	$self->start_mode('startInstall');
	$self->mode_param('rm');

	$self->run_modes(
		'startInstall'   => 'runModeStartInstall',
		'processInstall' => 'runModeProcessInstall',
		'AUTOLOAD'       => $self->can('runModeDefault')
	);

}

sub runModeStartInstall {
	my $self     = shift;
	my $errorMsg = shift;
	my $suggestion;
	my $forwarderPath;
	my $cssDir  = "myfavCss";
	my $baseUrl = $self->getBaseUrl();

	my $template = $self->load_tmpl("installer.tmpl");
	$template->param( "SCRIPTNAME" => $self->getCgiScriptName );

	if ($errorMsg) {
		$template->param( "ERRORMESSAGE" => "$errorMsg" );
	}

	# supply suggestions for forwarder dir
	my $documentRoot = $self->getCgiDocumentRoot();

	foreach my $entry ( sort ( keys %forwardDirSuggestions ) ) {

		$forwarderPath = $documentRoot . "/" . $forwardDirSuggestions{$entry};
		$suggestion    = $forwardDirSuggestions{$entry};

		if ( !$self->fileOrDirExists($forwarderPath) ) {
			last;
		}
	}
	$template->param( "FORWARDERDIR" => $suggestion );
	$template->param( "BASEURL" => $baseUrl );

	my $cssPath = $documentRoot . "/" . $cssDir;
	$template->param( "CSSPATH" => $cssPath );
	$template->param( "CSSDIR"  => $cssDir );
	$template->param( "DOCROOT" => $documentRoot );

	return $template->output;
}

sub runModeProcessInstall {
	my $self = shift;

	my %cgiParams    = $self->getCgiParamsHash();
	my $inputChecker = MyFav::CheckInput->new(%cgiParams);
	my $error        = $inputChecker->checkGeneralPasswordChange();

	my $forwarderDir = $self->getForwarderDir();
	my $cssDir       = $self->getCssDir();
	my $documentRoot = $self->getCgiDocumentRoot();

	my $forwarderPath = $documentRoot . "/" . $forwarderDir;
	my $cssPath       = $documentRoot . "/" . $cssDir;

	if ($error) {
		return $self->runModeStartInstall($error);
	}

	elsif ( $self->fileOrDirExists($forwarderPath) ) {
		return $self->runModeStartInstall(
"The central web directory '$forwarderDir' is already existing. Choose a different one."
		);
	}

	elsif ( $self->fileOrDirExists($cssPath) ) {
		return $self->runModeStartInstall(
"The style sheet directory '$cssDir' is already existing. Choose a different one."
		);
	}
	# everything fine, carry out install tasks
	else {
		my $baseUrl      = $self->getBaseUrl();
		my $cssUrl       = $baseUrl . "/" . $cssDir . '/css/my_layout.css';
		my $forwarderUrl = $baseUrl . "/" . $forwarderDir;

		my $cgiHttpPath = dirname( $self->getMyCurrentUrl() );

		my $downloadCgiPath = $cgiHttpPath . "/DownloadFile.cgi";
		my $loginCgiPath    = $cgiHttpPath . "/Login.cgi";
		my $releasesCgiPath  = $cgiHttpPath . "/Releases.cgi";

		eval {

			# copy css to www area + test accessiblity
			dircopy( "../myfavCss", $cssPath ) or die $!;
			$self->urlAccessible($cssUrl)
			  or die "Can't access style sheet file under $cssUrl";

			# create $forwarderPath, write a testfile inside, try to open it via
			# a http call and delete test file afterwards
			mkpath($forwarderPath) or die "Could not create $forwarderPath";
			$self->writeTestFile("$forwarderPath/test.txt");
			$self->urlAccessible("$forwarderUrl/test.txt")
			  or die "Can't access content under $forwarderUrl";
			unlink "$forwarderPath/test.txt"
			  or die "Can't delete under $forwarderUrl";
		};

		if ($@) {
			return "The installation has failed. Please correct the error and \
			        repeat the install process. \
			        Error: $@";
		}

		my $configDb = $self->createConfigDbObject();
		
		# if there is an existing configDb delete it
		if ($configDb->dataBaseExists()) {
			unlink $configDb->getFilePath();
		}

		$configDb->createConfigDataBase();
		$configDb->fillWithConfigDefaults();

		# fill all the installer inputs into the config db
		$configDb->updateDownloadCgiPath($downloadCgiPath);
		$configDb->updateLoginCgiPath($loginCgiPath);
		$configDb->updateForwarderDir($forwarderPath);
		$configDb->updateDownloadDefaultPath($forwarderUrl);
		$configDb->updateCssPath($cssUrl);
		
		my $newPassword = $self->getNewPassword();
		$newPassword = $self->getHashedValue($newPassword);
		$configDb->updatePassword($newPassword);
		
		my $scriptFileName = $self->getScriptFileName();
		
		
		eval {
			# prevent re-executing script after successfull setup.
			chmod 0400, $scriptFileName or die "I could not remove the execution rights of the installer script. \
			Please take away the execution rights of $scriptFileName \
			or delete the file completely. Otherwise everyone is able to run the installer via the web again which \
			would delete most of your data.";
		
			# check for directory listings
			if ($self->urlAccessible("$forwarderUrl/")) {
				die "Please don't ignore this error, this is serious!! The content of $forwarderUrl is listable by everyone via the web. 
				Since this directory will contain the links to your downloads you MUST protect it. \
				If you are running on Apache try putting the file .htaccess inside $forwarderPath \
				with this content: Options -Indexes\n";
			};
		};
		
		if ($@) {
			return "The installation completed successfully. However this error occured: $@ \
			        When you have fixed this error you can login here: $releasesCgiPath"
		}
		return $self->redirect("$releasesCgiPath");
	}
}

sub fileOrDirExists {
	my $self = shift;
	my $path = shift;

	# get rid of '//' instead of '/' in the path
	$path =~ s#//#/#;

	if ( $self->directoryExists($path) || $self->fileExists($path) ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub getBaseUrl {
	my $self = shift;

	my $baseUrl =
	    $self->getCgiServerProtocol()
	  . $self->getCgiServername()
	  . $self->getCgiServerPort();

	return $baseUrl;
}

sub writeTestFile {
	my $self         = shift;
	my $testFilePath = shift;

	open( FH, ">$testFilePath" )
	  or die
"Can't write testfile $testFilePath. Are the directory permissions set correctly?";
	print FH " ";
	close(FH);
}

sub getNewPassword {
	my $self = shift;

	my $cgi = $self->query();
	return $cgi->param("newPassword1");
}

sub getForwarderDir {
	my $self = shift;

	my $cgi = $self->query();
	return $cgi->param("forwarderDir");
}

sub getCssDir {
	my $self = shift;

	my $cgi = $self->query();
	return $cgi->param("cssDir");
}

sub getScriptFileName {
	return $ENV{'SCRIPT_FILENAME'};
}

1;