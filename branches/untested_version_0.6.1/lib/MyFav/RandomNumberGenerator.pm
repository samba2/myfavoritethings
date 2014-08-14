package MyFav::RandomNumberGenerator;

use strict;
use String::Random; # local
use Carp;

sub new {
	my $class = shift;

	croak "Illegal parameter list has odd number of values"
	  if @_ % 2;

	my (%params) = @_;

	bless {}, $class;
}

sub generateCodes {
	my $self = shift;
	my $codeCount = shift;
	my %codeHash;
	
    for ( my $i=1;$i <= $codeCount; $i++) {
        my $exists = 1;
        while ($exists == 1) {
			my $code = $self->generateSingleCode(6);
            if ($codeHash{$code}) {$exists = 1}
            else {
                $codeHash{$code} = 1;
                $exists = 0;
           }
       }
    }
    my @result = keys %codeHash;
    
	return @result; 	
}

sub generateSingleCode {
	my $self = shift;
	my $codeLength = shift;
	
	my $randPattern;
	
	# build random pattern for randpattern function, like 'AAA' or 'AAAAA'
	for (my $i=1; $i <= $codeLength; $i++ ) {
		$randPattern .= "A";	
	}

    my $random = new String::Random;
    $random->{'A'} = [ 'A','B','C','D','E','F','G','H','J','K','L','M','N','P','Q','R','S','T','U','V','W','X','Y','Z' ];
    my $code = $random->randpattern($randPattern); 
	
	return $code;	
}

1;
