package MyFav::SubApps::RPC;

use strict;
use CGI::Carp qw ( fatalsToBrowser );
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;
use MyFav::DB::ReleaseDB;
use MyFav::CheckInput;

use base 'MyFav::Base';

# overwrite base, output json error if not logged in
sub cgiapp_prerun {
    my $self = shift;
    $self->setupSession();

    if ( ! $self->session->param('~logged-in') ) {
        print $self->_send_headers();
        print $self->runModePrintError("Not logged in!");
        $self->teardown();
        exit;
    }
}

sub setup {
	my $self = shift;
    $self->header_add( -type => 'text/plain' );

	$self->start_mode('printError');
	$self->mode_param('rm');
	$self->run_modes(
		'printError'  => 'runModePrintError',
		'getCodeStatus'  => 'runModeGetCodeStatus',
		'resetCode' => 'runModeResetCode',
		'AUTOLOAD'     => $self->can('runModePrintError')
	);
}

sub runModePrintError {
    my $self = shift;
    my $error = shift;
    
    if ( $error ) {
        return "{\"error\": \"$error\"}";
    }
    else {
        return '{"error": "Sorry, an error occured"}';
    }
}

sub runModeGetCodeStatus {
    my $self = shift;
    my $releaseId = $self->getReleaseId();
    my $downloadCode = $self->getDownloadCode();
    my $allowReset = ',"allowReset":1';
    
    # check releaseId input
    my $configDb  = $self->createConfigDbObject();
    if ( ! $configDb->releaseExistsInConfigDb($releaseId) ) {
        return $self->runModePrintError("Release '$releaseId' not found");    
    }

    # check download code input
    my $inputChecker = $self->getInputChecker();
    my $downloadCodeFormatError = $inputChecker->checkDownloadCode();
    
    if ( $downloadCodeFormatError) {
        return $self->runModePrintError($downloadCodeFormatError);
    } 
    
    my $releaseDb  = $self->getReleaseDb($releaseId);
    my $codeExists = $releaseDb->codeExists($downloadCode);
    
    my $output = '{"codeStatus":';

    if ( $codeExists ) {
        if ( ! $releaseDb->codeIsUsed($downloadCode) ) {
            $output .= "\"Code '$downloadCode' is unused.\"";  
        }
        elsif ( $self->codeIsInsideDownloadTimeFrame( $releaseId, $downloadCode ) ) {
            $output .= "\"Code '$downloadCode' is used and still inside the download frame.\"";
            $output .= $allowReset;
        }
        else {
            $output .= "\"Code '$downloadCode' has expired.\"";
            $output .= $allowReset;
        }     
    }
    else {
        $output .= "\"Code '$downloadCode' does not exist.\"";
    }
    
    $output .= '}';
    
    return $output;
}

sub runModeResetCode {
    my $self = shift;
    my $releaseId = $self->getReleaseId();
    my $downloadCode = $self->getDownloadCode();
    
    my $releaseDb  = $self->getReleaseDb($releaseId);
    
    # check releaseId input
    my $configDb  = $self->createConfigDbObject();
    if ( ! $configDb->releaseExistsInConfigDb($releaseId) ) {
        return $self->runModePrintError("Release '$releaseId' not found");    
    }

    # check download code input
    my $inputChecker = $self->getInputChecker();
    my $downloadCodeFormatError = $inputChecker->checkDownloadCode();
    
    if ( $downloadCodeFormatError) {
        return $self->runModePrintError($downloadCodeFormatError);
    } 

    my $output = '{"codeStatus":';   

    if ( $releaseDb->codeExists($downloadCode) ) {
        if ( $releaseDb->codeIsUsed($downloadCode) ) {
            # reset code
            $releaseDb->setCodeToUnused($downloadCode);
            
            if ( $releaseDb->codeIsUsed($downloadCode) ) {
                $output .= "\"Reset of '$downloadCode' failed.\"";
            }    
            else {
                 $output .= "\"Code '$downloadCode' was set to 'unused'.\"";       
            } 
        }
        else {
            $output .= "\"Code '$downloadCode' is 'unused', no need to reset.\"";
        }
    }
    else {
        $output .= '"Code does not exist."';    
    }
    $output .= '}';

    return $output;   
}

1;
