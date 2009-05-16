#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the TaskChange model.

=cut

use lib 't/lib';
use Jifty::Test tests => 14;
use Qublog::Test;
setup_test_user;

# Make sure we can load the model
use_ok('Qublog::Model::Task');
use_ok('Qublog::Model::TaskChange');

my $task = Qublog::Model::Task->new;
$task->create(
    name => 'This is a new test task',
);
ok($task->id, 'We have a task for testing');

{
    my $task_logs = $task->task_logs;
    is($task_logs->count, 1, 'create task log exists');

    my $task_log = $task_logs->first;
    is($task_log->task_changes->count, 0, 'creates do not have changes');
}

$task->set_status('done');

{
    my $task_logs = $task->task_logs;
    is($task_logs->count, 3, 'update task logs added');

    my $task_log = $task_logs->next; # skip this one
       $task_log = $task_logs->next;

    my $task_changes = $task_log->task_changes;
    is($task_changes->count, 1, 'a single update');

    my $task_change = $task_changes->first;
    is($task_change->name, 'status', 'change is status');
    is($task_change->old_value, 'open', 'was open');
    is($task_change->new_value, 'done', 'now done');

    $task_log = $task_logs->next;
    $task_changes = $task_log->task_changes;
    is($task_changes->count, 1, 'a single update');

    $task_change = $task_changes->first;
    is($task_change->name, 'completed_on', 'change is completed_on');
    is($task_change->old_value, undef, 'no old date');
    is($task_change->new_value, ''.$task->completed_on, 
        'new value is completed_on');

}

# TODO test how TaskChanges are grouped in an UpdateTask action
