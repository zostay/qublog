#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A test for the ChangeTimer action.

=cut

use lib 't/lib';
use Jifty::Test tests => 15;
use Qublog::Test;

# Make sure we can load the action
use_ok('Qublog::Action::ChangeTimer');

Jifty::Test->web;
setup_test_user;

sub test_timer {
    my $now = Jifty::DateTime->now;

    my $day = Qublog::Model::JournalDay->for_today;

    my $start_time = $now->clone->subtract( hours => 1 );
    my $stop_time  = $now->clone->add( hours => 1 );

    my $entry = Qublog::Model::JournalEntry->new;
    $entry->create(
        journal_day => $day,
        name        => 'Test',
        start_time  => $start_time,
        stop_time   => $stop_time,
    );

    my $timer = Qublog::Model::JournalTimer->new;
    $timer->create(
        journal_entry => $entry,
        start_time    => $start_time,
        stop_time     => $stop_time,
    );

    return $timer;
}

# HAPPY: change the start
{
    my $timer = test_timer;
    my $timer_change_action = Jifty->web->new_action(
        class  => 'ChangeTimer',
        record => $timer,
        arguments => {
            which    => 'start',
            new_time => '12:45 PM',
        },
    );
    $timer_change_action->run;

    $timer->load($timer->id);

    is($timer_change_action->result->success, 1, 'success');
    is($timer_change_action->result->message, 'Updated start time.', 
        'updated msg');
    is($timer->start_time->hms, '12:45:00', 'start changed');
}

# HAPPY: change the stop
{
    my $timer = test_timer;
    my $timer_change_action = Jifty->web->new_action(
        class  => 'ChangeTimer',
        record => $timer,
        arguments => {
            which    => 'stop',
            new_time => '12:45 PM',
        },
    );
    $timer_change_action->run;

    $timer->load($timer->id);

    is($timer_change_action->result->success, 1, 'success');
    is($timer_change_action->result->message, 'Updated stop time.', 
        'updated msg');
    is($timer->stop_time->hms, '12:45:00', 'stop changed');
}

# HAPPY: change the start/day
{
    my $timer = test_timer;
    my $timer_change_action = Jifty->web->new_action(
        class  => 'ChangeTimer',
        record => $timer,
        arguments => {
            which       => 'start',
            new_time    => '1999-9-9 12:45 PM',
            change_date => 1,
        },
    );
    $timer_change_action->run;

    $timer->load($timer->id);

    is($timer_change_action->result->success, 1, 'success');
    is($timer_change_action->result->message, 'Updated start time.', 
        'updated msg');
    is($timer->start_time->ymd, '1999-09-09', 'start changed date');
    is($timer->start_time->hms, '12:45:00', 'start changed time');
}

# HAPPY: change the stop/day
{
    my $timer = test_timer;
    my $timer_change_action = Jifty->web->new_action(
        class  => 'ChangeTimer',
        record => $timer,
        arguments => {
            which       => 'stop',
            new_time    => '1999-9-9 12:45 PM',
            change_date => 1,
        },
    );
    $timer_change_action->run;

    $timer->load($timer->id);

    is($timer_change_action->result->success, 1, 'success');
    is($timer_change_action->result->message, 'Updated stop time.', 
        'updated msg');
    is($timer->stop_time->ymd, '1999-09-09', 'stop changed date');
    is($timer->stop_time->hms, '12:45:00', 'stop changed time');
}
