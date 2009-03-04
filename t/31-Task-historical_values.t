#!/usr/bin/perl
use strict;
use warnings;

use Jifty::Test tests => 13;

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

my $history = $task->historical_values;
is(scalar @$history, 4, 'got four changes of state');

is($history->[0]{span}->start, $task->created_on, 'first entry starts on original create date');
is($history->[-1]{span}->end, 'inf', 'last entry is the future');

is($history->[0]{name}, 'Testing', 'first name is Testing');
is($history->[1]{name}, 'Testing 2', 'second is Testing 2');
is($history->[2]{name}, 'Testing 3', 'third is Testing 3');
is($history->[3]{name}, 'Testing 4', 'fourth is Testing 4');
