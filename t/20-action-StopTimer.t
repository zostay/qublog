#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A test harness for the StartTimer action.

=cut

use lib 't/lib';
use Jifty::Test tests => 7;
use Qublog::Test;
setup_test_user;

# Make sure we can load the action
use_ok('Qublog::Action::StopTimer');

my $entry = test_entry();

{
    my $timers = $entry->timers;
    is($timers->count, 1, 'one timer');
    ok($timers->first->is_running, 'timer is running');
}

my $action = Jifty->web->new_action(
    class  => 'StopTimer',
    record => $entry,
);
$action->run;

ok($action->result->success, 'successful start');
is($action->result->message, 'Stopped', 'message is stopped');

{
    my $timers = $entry->timers;
    $timers->order_by({ column => 'start_time' });
    is($timers->count, 1, 'one timer still');
    ok($timers->first->is_stopped, 'timer is stopped');
}
