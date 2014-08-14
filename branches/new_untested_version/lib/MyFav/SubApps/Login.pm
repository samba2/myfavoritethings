package MyFav::SubApps::Login;

use strict;
use MyFav::CheckInput;
use CGI::Carp qw ( fatalsToBrowser );
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Redirect;
use MIME::Base64;
use MyFav::DB::ConfigDB;
use MyFav::DB::RateLimitDB;

use base 'MyFav::Base';
use CGI::Application::Plugin::RateLimit;

my $inputChecker;

sub setup {
	my $self = shift;
	my %cgiParams = $self->getCgiParamsHash();
	my $inputChecker = MyFav::CheckInput->new(%cgiParams);
	$self->setInputChecker($inputChecker);
	
	$self->setupSession();

	$self->tmpl_path( $self->getTemplatePath );
	$self->start_mode('loginScreen');
	$self->mode_param('rm');
	$self->run_modes(
		'loginScreen'  => 'runModeLoginScreen',
		'processLogin' => 'runModeProcessLogin',
		'rateLimitExceeded' => $self->can('runModeRateLimitExceeded'),
		'AUTOLOAD'     => $self->can('runModeDefault')

	);
	my $rateLimiter = $self->initRateLimiter();
	
	my $configDb = $self->createConfigDbObject();
	
	# protect runmode processLogin by rate limiter
	$rateLimiter->protected_modes(processLogin => {timeframe => $configDb->getRateLimiterTimeFrame(),
                                          max_hits  => $configDb->getRateLimiterMaxHits()
                                         });
}

# overwrite super method to prevent being redirect to myself
sub cgiapp_prerun {
}

sub runModeLoginScreen {
	my $self  = shift;
	my $error = shift;

	my $template = $self->load_tmpl("releasesLogin.tmpl");
	$template->param( "SCRIPTNAME" => $self->getCgiScriptName );

	#conserve the origin variable received by the forward
	# for processing in the next run mode
	$template->param( "ORIGIN" => $self->getOrigin() );

	# add error message if login was wrong
	if ($error) {
		$template->param( "ERRORMESSAGE" => $error );
	}

	$self->session->param( 'cookieTest', 'true' );

	return $self->renderPage( $template, "pageIsPublic" );
}

sub runModeProcessLogin {
	my $self = shift;

	my $error = $inputChecker->checkLoginPassword();

	if ($error) {
		return $self->runModeLoginScreen($error);
	}
	elsif ( $self->session->param('cookieTest') ne 'true' ) {
		return $self->runModeLoginScreen(
			"Sorry, you need to enable 'cookies' in your browser to login.");
	}

	# we're in...
	else {
		$self->session->clear('cookieTest');
		$self->session->param( '~logged-in', 'true' );

		# redirect url is passed over as base64 encoded string, convert back
		my $origin = decode_base64( $self->getOrigin() );

		return $self->redirect("$origin");
	}
}

sub getOrigin {
	my $self      = shift;
	my %cgiParams = $self->getCgiParamsHash();
	return $cgiParams{"o"};
}

sub getInputChecker {
	return $inputChecker;
}

sub setInputChecker {
	my $self = shift;
	my $value = shift;
	
	$inputChecker = $value;
}

1;
