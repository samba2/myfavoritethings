package TestContainer;

use Text::Trim;
use Time::HiRes qw/sleep/;

use strict;
use v5.10;

my $MYFAV_DOCKER_IMAGE_NAME = "myfav";

sub new {
    my $class = shift;
	my (%params) = @_;

	bless {%params}, $class;

}

sub start {
    my $self = shift;
    $self->{container_id} = trim(`docker run --publish 80:80 --detach --rm $MYFAV_DOCKER_IMAGE_NAME`);
}

sub stop {
    my $self = shift;
    my $container_id = $self->{container_id};

    if ($self->{debug}) {
        system("docker logs $container_id");    
    }

    system("docker rm -f $container_id >/dev/null");
}

sub is_healty {
    my $container_id = shift->{container_id};
    my $container_status = trim(`docker inspect --format='{{json .State.Health.Status}}' $container_id`);
    return $container_status eq '"healthy"';
}


sub block_until_available {
    my $self = shift;
    print "Waiting for testcontainer to become ready";

    while (! $self->is_healty()) {
        print ".";
        sleep 0.5;
    }
    print "\n";
}

# convinience method
sub start_and_block_until_available {
    my $debug = shift;

    my $c = TestContainer->new('debug' => $debug);
    $c->start();
    $c->block_until_available();
    return $c;
}

sub execute() {
    my $self = shift;
    my $cmd = shift;
    my $container_id = $self->{container_id};
    return trim(`docker exec $container_id $cmd`);
}

sub getContainerId() {
    my $self = shift;
    return $self->{container_id};
}

1;