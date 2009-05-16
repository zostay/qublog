#!/usr/bin/perl
use strict;
use warnings;

use lib 't/lib';
use Jifty::Test tests => 12;
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

my $history = $task->historical_values;
is(scalar @$history, 4, 'got four changes of state');

is($history->[0]{span}->start, $task->created_on, 'first entry starts on original create date');
is($history->[-1]{span}->end, 'inf', 'last entry is the future');

is($history->[0]{name}, 'Testing', 'first name is Testing');
is($history->[1]{name}, 'Testing 2', 'second is Testing 2');
is($history->[2]{name}, 'Testing 3', 'third is Testing 3');
is($history->[3]{name}, 'Testing 4', 'fourth is Testing 4');
