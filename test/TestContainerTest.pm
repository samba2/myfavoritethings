package TestContainerTest;
use base qw(Test::Class);
use Test::More;

use TestContainer;

use v5.10;

sub starts_and_stops_container: Test {
    my $c = TestContainer->new();
    isa_ok($c, 'TestContainer');

    $c->start();
    $c->block_until_available();
    $c->stop();

    my $remaining_containers = `docker ps -q`;
    is($remaining_containers, "", "No container left over");
}

1;