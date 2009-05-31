#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A test harness for the CreateTask action.

=cut

use lib 't/lib';
use Jifty::Test tests => 4;
use Qublog::Test;
setup_test_user;

# Make sure we can load the action
use_ok('Qublog::Action::CreateTask');

my $action = Jifty->web->new_action(
    class  => 'CreateTask',
);
$action->argument_value( name => '#foo: Testing 123' );
$action->run;

ok($action->result->success, 'successful action');
#is($action->result->message, 'Created task', 'create message');

my $task = $action->record;
is($task->name, 'Testing 123', 'name is shortened');
is($task->tag, 'foo', 'tag_name is foo');
