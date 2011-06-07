package MyFav::DB::RateLimitDB;

use strict;
use CGI::Carp qw ( fatalsToBrowser );  

use base 'MyFav::DB::General';

sub createRateLimitDataBase {
	my $self = shift;
	my $dataBaseName = $self->getDataBaseName();

    $self->writeToDataBase("CREATE TABLE $dataBaseName (user_id VARCHAR(255), action VARCHAR(255), timestamp VARCHAR(255))");
}


# get rid of old timestamps in database which are older than my timeframe
# hence timeframe has to be setup in seconds
sub deleteOldEntries {
	my $self = shift;
	my $dataBaseName = $self->getDataBaseName();

	my $configDb = MyFav::DB::ConfigDB->new(
		"dataBaseName" => "config",
		"dataBaseDir"  => $self->getDataBaseDir()
	);
	
	my $timeframe = $configDb->getRateLimiterTimeFrame();
	# remove "s" at the end of string
	$timeframe =~ s/\D\Z//; 
	
	my $oldestTimeStamp = time() - $timeframe;
	
	$self->writeToDataBase("DELETE FROM $dataBaseName WHERE timestamp < $oldestTimeStamp");
}

1;
