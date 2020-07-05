package TestContainer;

use v5.10;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub start {
    shift->{container_id} = `docker run --publish 80:80 --detach --rm myfavoritethings-test`;
}

sub stop {
    my $container_id = shift->{container_id};
    system("docker rm -f $container_id");
}

sub is_healty {
    my $container_id = shift->{container_id};
    chomp (my $container_status = `docker inspect --format='{{json .State.Health.Status}}' $container_id`);
    return $container_status eq '"healthy"';
}


sub block_until_available {
    my $self = shift;
    print "Waiting for testcontainer to become healthy";

    while (! $self->is_healty()) {
        print ".";
        sleep 1;
    }
    print "\n";
}

1;