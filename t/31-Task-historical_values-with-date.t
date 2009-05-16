#!/usr/bin/perl
use strict;
use warnings;

use lib 't/lib';
use Jifty::Test tests => 7;
use Qublog::Test;
setup_test_user;

use_ok('Qublog::Model::Task');

my $task = Qublog::Model::Task->new;
$task->create( name => 'Testing' );
ok($task->id, 'got a task');

sleep 1;
ok($task->set_name('Testing 2'), 'changed name');

sleep 1;
ok($task->set_name('Testing 3'), 'changed name');

sleep 1;
ok($task->set_name('Testing 4'), 'changed name');

{
    my $history = $task->historical_values(Jifty::DateTime->now);
    is($history->{name}, 'Testing 4', 'current is Testing 4');
}

{
    my $history = $task->historical_values($task->created_on);
    is($history->{name}, 'Testing', 'original is Testing');
}
