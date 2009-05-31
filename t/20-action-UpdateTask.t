#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A test harness for the UpdateTask action.

=cut

use lib 't/lib';
use Jifty::Test tests => 10;
use Qublog::Test;
setup_test_user;

# Make sure we can load the action
use_ok('Qublog::Action::UpdateTask');

my $task = test_task();

{
    my $logs = $task->task_logs;
    is($logs->count, 1, 'got one log');
    is($logs->first->log_type, 'create', 'log is create');
}

my $action = Jifty->web->new_action(
    class  => 'UpdateTask',
    record => $task,
);
$action->argument_value( name => 'This is a test.' );
$action->run;

{
    my $logs = $task->task_logs;
    is($logs->count, 2, 'got two logs');
    is($logs->first->log_type, 'create', 'first log is create');

    my $update = $logs->last;
    is($update->log_type, 'update', 'last log is update');
    is($update->task_changes->count, 1, 'one task change');

    my $task_change = $update->task_changes->first;
    is($task_change->name, 'name', 'name changed');
    is($task_change->old_value, 'Testing', 'name changed from Testing');
    is($task_change->new_value, 'This is a test.', 'name changed to This is a test.');
}
