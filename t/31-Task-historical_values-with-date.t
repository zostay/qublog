#!/usr/bin/perl
use strict;
use warnings;

use Jifty::Test tests => 8;

use_ok('Qublog::Model::Task');

my $system_user = Qublog::CurrentUser->superuser;
ok($system_user, 'got a system user');
my %su = ( current_user => $system_user );

my $task = Qublog::Model::Task->new(%su);
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
