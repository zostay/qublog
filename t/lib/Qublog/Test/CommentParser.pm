use strict;
use warnings;

package Qublog::Test::CommentParser;
use base qw( Test::Class );

INIT { Test::Class->runtests }

use Jifty::Everything;
use Jifty::Test;

# Some initial setup
Jifty->new;
Jifty::Test->web;

our $NOT_A_TEST = 1;

sub setup_tests : Test(setup) {
    my $self = shift;

    # Each test class uses the same project throughout
    unless ($self->{project}) {

        # Setup a generic project to reuse
        my $project = Qublog::Model::Task->new;
        $project->create( name => 'Testing' );
        $project->set_parent( undef );
        $self->{project} = $project;
    }

    # This only needs to be set once
    unless ($self->{day}) {

        # Setup a generic day
        my $day = Qublog::Model::JournalDay->for_today;
        $self->{day} = $day;
    }

    # This only needs to be set once
    unless ($self->{entry}) {

        # Setup an entry
        my $entry = Qublog::Model::JournalEntry->new;
        $entry->create(
            journal_day => $self->{day},
            name        => 'Testing',
            project     => $self->{project},
        );
        $self->{entry} = $entry;
    }

    # This only needs to be set once
    unless ($self->{timer}) {

        # Setup a timer
        my $timer = $self->{entry}->start_timer;
        $self->{timer} = $timer;
    }

    # Setup a generic comment for each test method
    my $comment = Qublog::Model::Comment->new;
    $comment->create(
        journal_day   => $self->{day},
        journal_timer => $self->{timer},
        name          => 'XXX',
    );
    $self->{comment} = $comment;
}

sub number_of_task_logs_is {
    my ($self, $type, $number) = @_;

    my $task_logs = $self->{comment}->task_logs;

    if ($type ne 'all') {
        $task_logs->limit(
            column => 'log_type',
            value  => $type,
        );
    }

    is($task_logs->count, $number, "number of task logs of type $type is $number");

    return @{ $task_logs->items_array_ref };
}

1;
