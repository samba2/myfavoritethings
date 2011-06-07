package MyFav::SubApps::Install;

use strict;
use MyFav::DB::ConfigDB;
use MyFav::CheckInput;
use CGI::Carp qw ( fatalsToBrowser );
use File::Path qw ( mkpath );
use File::Basename;
use File::Copy::Recursive qw ( dircopy );
use CGI::Application::Plugin::Redirect;
use Exception::Class('MyFav::Install::ChmodFailed',
                     'MyFav::Install::UrlNotAccessible',
                     'MyFav::Install::WebLibCopyFailed',
                     'MyFav::Install::WebLibNotAccessible',
                     'MyFav::Install::NoDeleteInWebLibs',
                     'MyFav::Install::CantCreateForwarderPath',
                     'MyFav::Install::NoAccessToForwarderUrl',
                     'MyFav::Install::NoWriteInForwarderPath'
                     );

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
	my $webLibDir  = "myfavLibs";
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

	$template->param( "WEB_LIB_DIR"  => $webLibDir );
	$template->param( "DOCROOT" => $documentRoot );

	return $template->output;
}

sub runModeProcessInstall {
	my $self = shift;

	my %cgiParams    = $self->getCgiParamsHash();
	my $inputChecker = MyFav::CheckInput->new(%cgiParams);
	my $error        = $inputChecker->checkGeneralPasswordChange();

	my $forwarderDir = $self->getForwarderDir();
	my $webLibDir       = $self->getWebLibDir();
	my $documentRoot = $self->getCgiDocumentRoot();

	my $forwarderPath = $documentRoot . "/" . $forwarderDir;
	my $webLibPath       = $documentRoot . "/" . $webLibDir;

	if ($error) {
		return $self->runModeStartInstall($error);
	}

	elsif ( $self->fileOrDirExists($forwarderPath) ) {
		return $self->runModeStartInstall(
"The central web directory '$forwarderDir' is already existing. Choose a different one."
		);
	}

	elsif ( $self->fileOrDirExists($webLibPath) ) {
		return $self->runModeStartInstall(
"The directory '$webLibDir' is already existing. Choose a different one."
		);
	}
	# everything fine, carry out install tasks
	else {
		my $baseUrl      = $self->getBaseUrl();
		my $webLibBaseUrl       = $baseUrl . "/" . $webLibDir;
		my $forwarderUrl = $baseUrl . "/" . $forwarderDir;

		my $cgiHttpPath = dirname( $self->getMyCurrentUrl() );

		my $downloadCgiPath = $cgiHttpPath . "/DownloadFile.cgi";
		my $loginCgiPath    = $cgiHttpPath . "/Login.cgi";
		my $releasesCgiPath = $cgiHttpPath . "/Releases.cgi";
		my $myfavLibSrc     = $self->getWebLibPath();

        my $template = $self->load_tmpl("installerAbort.tmpl");

		eval {

			# copy libs to www area + test accessiblity
			dircopy( $myfavLibSrc , $webLibPath ) or MyFav::Install::WebLibCopyFailed->throw( error=>$! );
            $self->writeTestFile("$webLibPath/test.txt");

			unless ($self->urlAccessible("$webLibBaseUrl/")) {
			    MyFav::Install::WebLibNotAccessible->throw();
			} 
			
			unlink "$webLibPath/test.txt"
              or MyFav::Install::NoDeleteInWebLibs->throw();
			
			# create $forwarderPath, write a testfile inside, try to open it via
			# a http call and delete test file afterwards
			mkpath($forwarderPath) or MyFav::Install::CantCreateForwarderPath->throw( error=>$! );

			$self->writeTestFile("$forwarderPath/test.txt");
			$self->urlAccessible("$forwarderUrl/test.txt")
			  or MyFav::Install::NoAccessToForwarderUrl->throw();
			  
			unlink "$forwarderPath/test.txt"
			  or MyFav::Install::NoWriteInForwarderPath->throw();

            # create .htaccess file to prevent listing of dirs inside $forwarderPath via browser
            $self->writeHtaccessFile("$forwarderPath/.htaccess");	
		};

        my $e = Exception::Class->caught();  
        
        if ( $e ) {
            $template->param( "WEB_LIB_PATH" => $webLibPath);
            $template->param( "ERROR_DESC" => $e->error );
            
            if ( $e = Exception::Class->caught('MyFav::Install::WebLibCopyFailed') ) {
                $template->param( "WEB_LIB_COPY_FAILED" => "1" );
                $template->param( "WEB_LIB_SOURCE"  => $myfavLibSrc );
            }
            elsif ($e = Exception::Class->caught('MyFav::Install::WebLibNotAccessible')) {
                $template->param( "NO_WEB_ACCHESS" => "1" );
                $template->param( "TEST_URL" => "$webLibPath/test.txt" );
            }
            elsif ($e = Exception::Class->caught('MyFav::Install::CantCreateForwarderPath')) {

                $template->param( "CANT_CREATE_FORWARDER_PATH" => "1" );
                $template->param( "FORWARDER_PATH" => $forwarderPath);
            }
            elsif ($e = Exception::Class->caught('MyFav::Install::NoAccessToForwarderUrl')) {
                $template->param( "NO_WEB_ACCHESS" => "1" );  
                $template->param( "TEST_URL" => "$forwarderUrl/test.txt" );                              
            } 
            elsif ($e = Exception::Class->caught('MyFav::Install::NoWriteInForwarderPath')) {
                $template->param( "NO_WRITE_IN_FORWARDER_PATH" => "1" );      
                $template->param( "FORWARDER_TEST_FILE" => "$forwarderPath/test.txt" );          
            }             
            return $template->output;
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
		$configDb->updateWebLibBaseUrl($webLibBaseUrl);
		
		my $newPassword = $self->getNewPassword();
		$newPassword = $self->getHashedValue($newPassword);
		$configDb->updatePassword($newPassword);
		
		my $scriptFileName = $self->getScriptFileName();
		
        # needs to be loaded before exception testing
        # otherwise exception handling is getting out of trap
        $template = $self->load_tmpl("installerSuccessWithError.tmpl");

		eval {
			# prevent re-executing script after successfull setup.
			chmod 0400, $scriptFileName or MyFav::Install::ChmodFailed->throw();
		
			# check for directory listings
            if ($self->urlAccessible("$forwarderUrl/")) { 
            	MyFav::Install::UrlNotAccessible->throw() 
            };
            
		};

        $e = Exception::Class->caught();	
        
        if ( $e ) {
            if ( $e = Exception::Class->caught('MyFav::Install::UrlNotAccessible') ) {
                $template->param( "FORWARD_DIR_ACCESSIBLE" => "1" );
                $template->param( "FORWARDERURL" => $forwarderUrl );
                $template->param( "FORWARDERPATH_HTACCESS" => "$forwarderPath/.htaccess" );  
            }
            elsif ( $e = Exception::Class->caught('MyFav::Install::ChmodFailed')) {
               $template->param( "CHMOD_FAILED" => "1" );
               $template->param( "SCRIPTFILENAME" => $scriptFileName );
            }
            $template->param( "RELEASECGIURL" => $releasesCgiPath );
            return $template->output;
		}
		else {
		    return $self->redirect("$releasesCgiPath");	
		} 
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

sub writeHtaccessFile {
	my $self         = shift;
	my $htaccessFilePath = shift;

	open( FH, ">$htaccessFilePath" )
	  or die
"Can't write htaccess file $htaccessFilePath. Are the directory permissions set correctly?";
	print FH "Options -Indexes";
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

sub getWebLibDir {
	my $self = shift;

	my $cgi = $self->query();
	return $cgi->param("webLibDir");
}

sub getScriptFileName {
	return $ENV{'SCRIPT_FILENAME'};
}

1;
