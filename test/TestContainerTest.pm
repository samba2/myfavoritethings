package TestContainerTest;
use base qw(Test::Class);
use Test::More;

use Text::Trim;
use TestContainer;

use v5.10;

sub starts_and_stops_container: Test {
    my $c = TestContainer->new('debug' => true);
    isa_ok($c, 'TestContainer');

    $c->start();
    $c->block_until_available();
    $c->stop();

    my $remaining_containers = `docker ps -q`;
    is($remaining_containers, "", "No container left over");
}

sub provides_quick_start: Test {
    my $c = TestContainer->start_and_block_until_available();
    $c->stop();
    
    ok(1, "quickstart works");
}


sub can_execute_a_system_command: Test {
    my $c = TestContainer->new();
    $c->start();
    $c->block_until_available();

    my $result = $c->execute("whoami");
    is( $result, "root", "running as root");

    $c->stop();
}

1;