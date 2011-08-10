package MyFav::Base;

use strict;
use CGI::Carp qw ( fatalsToBrowser );
use Digest::MD5;     # core lib
use URI::Escape;     # local lib
use Date::Format;    # local lib
use HTTP::Lite;      # local lib
use Time::Local;     #core lib
use MyFav::DB::RateLimitDB;
use CGI::Application::Plugin::Session; # local
use CGI::Application::Plugin::Redirect;  #local
use MIME::Base64;  # core 
use File::Basename;  # core

use base 'CGI::Application';

# had to adapt module to get it running with dbd::anydata
# the following SQL access methods where changed:
# record_hit_sth, check_violation_sth, revoke_hit_sth
# changed "$dbh->quote_identifier($self->table)" to "$self->table" 
use CGI::Application::Plugin::RateLimit;

# constants
my $dataBaseDir = "../data";
my $templatePath = '../html';
my $webLibPath = '../myfavLibs';
my $fileDir = "../upload_files";
my $sessionDir = "../sessions";
my $releaseDbPrefix = 'codes_for_';  # prefix for releaseDb csv files, prevents non-alphanum. start of file

# implements login for admin modules like releases.pm and wizard.pm
sub cgiapp_prerun {
	my $self = shift;

	$self->setupSession();

	# not logged in, redirect to login.cgi
	if ( !$self->session->param('~logged-in') ) {
		my $myCurrentUrl = $self->getMyCurrentUrl();
		my $configDb = $self->createConfigDbObject();

		my $loginCgiPath = $configDb->getLoginCgiPath();
		my $encodedReleasesCgiPath =
		  $self->getEscapedValue( encode_base64($myCurrentUrl) );

		return $self->redirect("$loginCgiPath?o=$encodedReleasesCgiPath");
	}
}

##############################################
# Special Run Modes
##############################################

sub runModeDefault {
	return "Welcome to the end of the world. Its going to be really scarry out here."
}

sub runModeRateLimitExceeded {
	return "You have accessed this page too often."
}


##############################################
# CGI methods
##############################################

sub getMyCurrentUrl {
	my $self = shift;

	my $currentUrl =
		$self->getCgiServerProtocol()
	  . $self->getCgiServername()
	  . $self->getCgiServerPort()
	  . $self->getCgiScriptName();

	return $currentUrl;
}

sub getCgiScriptName {
	my $self  = shift;
	my $query = $self->query();
	return $query->script_name();
}

sub getCgiServername {
	my $self  = shift;
	my $query = $self->query();
	return $query->server_name();
}

sub getCgiServerPort {
	my $self  = shift;
	my $query = $self->query();
	my $port = $query->server_port();
	
	if ($port eq "80") {
		return "";
	}
	else {
		return ":$port";
	}
}

sub getCgiServerProtocol {
	my $self = shift;

	if ( $self->runningOnHttps() ) {
		return "https://";
	}
	else {
		return "http://";
	}
}

sub runningOnHttps {
	my $self  = shift;
	my $query = $self->query();

	if ( $query->https() ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub getCgiDocumentRoot {
	my $docRoot = $ENV{'DOCUMENT_ROOT'};
	# get rid of last slash
	$docRoot =~ s#/\Z##g;
	return $docRoot;
}

 
sub getCgiContentLength {
	return $ENV{'CONTENT_LENGTH'};
}

sub getCgiRemoteHost {
	if ($ENV{'REMOTE_HOST'}) {
		return $ENV{'REMOTE_HOST'}
	}
	else {
		return $ENV{'REMOTE_ADDR'};
	}
}

sub getCgiParamsHash {
	my $self = shift;

	my $query     = $self->query();
	my %cgiParams = $query->Vars;

	return %cgiParams;
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

sub getFileName {
    my $self      = shift;
    my %cgiParams = $self->getCgiParamsHash();
    return $cgiParams{"fileName"};
}

##############################################
# Methods dealing with template data
##############################################

sub renderPage {
	my $self        = shift;
	my $contentTmpl = shift;

	# if set the page is rendered for public access like the login-page
	# so internal menues are excluded
	my $isPublic = shift;

	my $configDb = $self->createConfigDbObject();

	my $startTmpl = $self->load_tmpl("pageStart.tmpl");
	$startTmpl->param( "VERSIONID" => $configDb->getVersionId() );
	$startTmpl->param( "WEB_LIB_PATH"   => $configDb->getWebLibBaseUrl() );
	
	if (! $isPublic) {
		$startTmpl->param( "INTERNAL"   => "1" );
	}

	my $menuTmpl = $self->load_tmpl("pageMenu.tmpl");
	my $cgiPath = dirname($self->getCgiScriptName);
	$menuTmpl->param( "CGIPATH"   => $cgiPath );	

	my $endTmpl = $self->load_tmpl("pageEnd.tmpl");

	my $finalPage = $startTmpl->output();

	# only display if not public (= logged in)
	if ( !$isPublic ) {
		$finalPage .= $menuTmpl->output();
	}

# only time of "inline html", i absolutelly promise ;-)
# puts the defaultContainer around the content to allow default formating via css
	$finalPage .=
	    "<div id=main>\n"
	  . $contentTmpl->output()
	  . "</div>\n"
	  . $endTmpl->output();

	return $finalPage;
}

# create template object + add default params
sub setupForm {
	my $self             = shift;
	my $templateName     = shift;
	my $internalErrorMsg = shift;

	my $configDb = $self->createConfigDbObject();
	
	my $template = $self->load_tmpl($templateName);
	$template->param( "SCRIPTNAME"   => $self->getCgiScriptName );
	$template->param( "ERRORMESSAGE" => $internalErrorMsg );

	return $template;
}


##############################################
# String methods
##############################################

sub getHashedValue {
	my $self  = shift;
	my $value = shift;

	my $hashHandle = Digest::MD5->new;
	$hashHandle->add($value);

	my $hashedValue = $hashHandle->b64digest;
	return $hashedValue;
}

sub getCurrentTimeString {
	my $timeString = time2str( '%Y%m%d%H%M%S', time );
	return $timeString;
}

sub getEpochTime {
	my $self       = shift;
	my $timeString = shift;
	my $epochString;

	if ( $timeString =~ m/\A(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)\Z/ ) {
		my $year = $1;
		my $mon  = $2 - 1;    # handles the time local offset
		my $mday = $3;
		my $hour = $4;
		my $min  = $5;
		my $sec  = $6;

		$epochString = timelocal( $sec, $min, $hour, $mday, $mon, $year );
	}
	return $epochString;
}

# handle url escaping of GET parameters
sub getEscapedValue {
	my $self           = shift;
	my $unEscapedvalue = shift;

	my $escapedValue = uri_escape("$unEscapedvalue");
	return $escapedValue;
}

sub getUnescapedValue {
	my $self         = shift;
	my $escapedValue = shift;

	my $unEscapedvalue = uri_escape("$escapedValue");
	return $unEscapedvalue;
}

sub getDateHash {
    my $self = shift;
    my $dateString = shift;

    if ( $dateString =~ m/\A(\d\d)(\d\d)(\d\d\d\d)\Z/) {
        my %dateHash  = (
            "month" => $1,
            "day" => $2,
            "year" => $3);
         return \%dateHash;   
    }       
}

sub isAnExpiryDate {
    my $self = shift;
    my $dateString = shift;
    
    if ($dateString =~ m/\A\d{8}\Z/) {
        return 1
    }
    else {
        return 0
    }
}

# only allow date if it is in range now <= date <= (date + approx. 500 years) 
sub isValidExpiryDate {
    my $self = shift;
    my $date = shift;
    my $validUntilYears = 500;
    
    my $dateHashRef = $self->getDateHash($date);  

    my $nowEpoch = time();

    # add seconds for 500 years to now, ignore leap years
    my $maxEpochTime = $nowEpoch + $validUntilYears * 365 * 24 * 60 * 60;         

    my $dateEpochTime;
    eval {
        $dateEpochTime = timelocal(00 ,00 ,00 ,$$dateHashRef{'day'} ,$$dateHashRef{'month'}-1, $$dateHashRef{year});
    };

    if ($nowEpoch < $dateEpochTime && $maxEpochTime > $dateEpochTime) {
        return 1;
    }       

    return 0;
} 

##############################################
# Setup and Init methods
##############################################

sub setupSession {
	my $self = shift;

	# expires after 120 min inactivity!
	my $sessionExpire = "120m";

	# change default session dir
	my $sessionHome = $self->getSessionDir();
	$self->session_config(
		CGI_SESSION_OPTIONS => [ undef, undef, { Directory => "$sessionHome" } ]
	);

	$self->session->expire("$sessionExpire");
}

sub initRateLimiter {
	my $self = shift;
	
	my $dataBaseDir = $self->getDataBaseDir();
	
	my $rateLimitDb=MyFav::DB::RateLimitDB->new("dataBaseName" => 'rate_limit_hits',
		"dataBaseDir"  => $dataBaseDir);

	if (! $rateLimitDb->dataBaseExists()) {
		$rateLimitDb->createRateLimitDataBase();	
	}	

	$rateLimitDb->deleteOldEntries();
	
	my $limterDbHandle = $rateLimitDb->getDataBaseHandle();	
	
	# load plugin
	my $rateLimter = $self->rate_limit();
	$rateLimter->dbh($limterDbHandle);
	$rateLimter->table('rate_limit_hits');
	# set which host should be recorded in collumn "user_id"
    $rateLimter->identity_callback(sub { $self->getCgiRemoteHost()});
    # which run mode should be displayed  
	$rateLimter->violation_mode('rateLimitExceeded');

	return $rateLimter;
}

sub getReleaseDb {
	my $self = shift;
	my $releaseId = shift;
	
	my $releaseDbName = $self->getReleaseDbPrefix() . $releaseId;
	my $releaseDb     = MyFav::DB::ReleaseDB->new(
		"dataBaseName" => $releaseDbName,
		"dataBaseDir"  => $self->getDataBaseDir()
	);
	
	return $releaseDb;
}

sub createConfigDbObject {
	my $self = shift;
	
	my $configDb =	MyFav::DB::ConfigDB->new(
		"dataBaseName" => "config",
		"dataBaseDir"  => $self->getDataBaseDir());
	return $configDb;	
}

sub getInputChecker {
    my $self = shift;

    my %cgiParams = $self->getCgiParamsHash();
    return MyFav::CheckInput->new(%cgiParams);
}


##############################################
# File access methods
##############################################

sub fileExists {
	my $self = shift;
	my $fileName = shift;
	
	if (-r $fileName) {
		return 1
	}
	else {
		return 0
	}
}

sub directoryExists {
	my $self = shift;
	my $dirName = shift;
	
	if (-d $dirName) {
		return 1
	}
	else {
		return 0
	}	
}

##############################################
# Misc. methods
##############################################

# returns an array of keys sorted by their value
sub sortHashByValue {
	my $self = shift;
	my (%unsortedHash) = @_;
	my @sortedKeys;

	foreach my $key (
		sort { $unsortedHash{$a} cmp $unsortedHash{$b} }
		keys %unsortedHash
	  )
	{
		push( @sortedKeys, $key );
	}
	return @sortedKeys;
}

# checks via http if url is accessible
# ! url has to in the following form:
# http://test.de/ but not http://test.de
# http://test.de/index.html
# only supports http
sub urlAccessible {
	my $self    = shift;
	my $testUrl = shift;

	my $http = new HTTP::Lite;

	eval {
		my $req = $http->request("$testUrl") or die;

		# check server returns a status code 2xx (=ok)
		die if ( $http->status !~ m/2\d\d/ );
	};
	if ($@) {
		return 0;
	}
	else {
		return 1;
	}
}

sub codeIsInsideDownloadTimeFrame {
	my $self         = shift;
	my $releaseId	 = shift;
	my $downloadCode = shift;
	
	my $releaseDb = $self->getReleaseDb($releaseId);
	my $configDb = $self->createConfigDbObject();

	my $oldTimeStamp = $releaseDb->getTimeStamp($downloadCode);
	$oldTimeStamp = $self->getEpochTime($oldTimeStamp);

	my $currentTimeStamp = time();
	my $expirationTimer  = $configDb->getExpirationTimer();

	# check expiration
	if ( $oldTimeStamp + $expirationTimer < $currentTimeStamp ) {
		return 0;
	}
	else {
		return 1;
	}
}

# handle upload from html form to server
sub uploadFile {
    my $self = shift;

    my $fileDir  = $self->getFileDir();
    my $fileName = $self->getFileName();

    my $query            = $self->query();
    my $uploadFileHandle = $query->upload('fileName');

    open( UPLOADFILE, ">$fileDir/$fileName" ) or die "$!";
    binmode UPLOADFILE;

    while (<$uploadFileHandle>) {
        print UPLOADFILE;
    }
    close UPLOADFILE;
}


##############################################
# Getter for constants
##############################################

sub getDataBaseDir {
	return $dataBaseDir;
}

sub getTemplatePath {
	return $templatePath;
}

sub getWebLibPath {
    return $webLibPath;
}

sub getFileDir {
	return $fileDir;
}

sub getSessionDir {
	return $sessionDir;
}

sub getReleaseDbPrefix {
	return $releaseDbPrefix;
}


1;
