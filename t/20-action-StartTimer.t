#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A test harness for the StartTimer action.

=cut

use lib 't/lib';
use Jifty::Test tests => 8;
use Qublog::Test;
setup_test_user;

# Make sure we can load the action
use_ok('Qublog::Action::StartTimer');

my $entry = test_entry();

{
    my $timers = $entry->timers;
    is($timers->count, 1, 'one timer');
    ok($timers->first->is_running, 'timer is running');
}

sleep 2;
$entry->stop_timer;

my $action = Jifty->web->new_action(
    class  => 'StartTimer',
    record => $entry,
);
$action->run;

ok($action->result->success, 'successful start');
is($action->result->message, 'Started', 'message is started');

{
    my $timers = $entry->timers;
    $timers->order_by({ column => 'start_time' });
    is($timers->count, 2, 'two timers');
    ok($timers->first->is_stopped, 'first timer is stopped');
    ok($timers->last->is_running, 'last timer is running');
}
