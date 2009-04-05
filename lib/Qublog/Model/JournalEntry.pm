use strict;
use warnings;

package Qublog::Model::JournalEntry;
use Jifty::DBI::Schema;

use DateTime;
use DateTime::Duration;
use Jifty::DateTime;

=head1 NAME

Qublog::Model::JournalEntry - groups journal timers together

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

Journal entries are used to group a set of timers together on a given day. This is done to help keep similar timers as a coherent group for reporting. For example, I might work on the documentation for a module for a particular client during two or three different time spans during the day. These can be grouped together as a whole to determine how much time I spent working for that client.

=head1 SCHEMA

=head2 journal_day

This is the L<Qublog::Model::JournalDay> to which this entry belongs.

=head2 name

This is the title for the journal entry.

=head2 description

DEPRECATED. Removed in 0.0.3. Should be removed from the class completely in the near future.

=head2 start_time

This is the time stamp noting the start of the first timer. This is generally the same as the C<start_time> of the very first L<Qublog::Model::JournalTimer> attached to the entry.

=head2 stop_time

This is the time stamp noting the end of the last timer. This is generally the same as the C<stop_time> of the very last L<Qublog::Model::JournalTimer> attached to the entry.

=head2 primary_link

This is a URL to attach to the entry to note an external reference that may provide more information about what is being worked on in this group.

=head2 project

This is the task upon which the entry is working on. All comments attached to timers attached to this entry will be logged to this task.

=head2 timers

This is a L<Qublog::Model::JournalTimerCollection> containiner the timers attached to this entry.

=cut

use Qublog::TimedRecord schema {
    column journal_day =>
        references Qublog::Model::JournalDay,
        label is 'Day',
        since '0.2.0',
        render as 'unrendered',
        ;

    column name =>
        type is 'text',
        label is 'Subject',
        is mandatory,
        ;

    column description =>
        type is 'text',
        label is 'Description',
        render as 'textarea',
        till '0.0.3',
        ;

    column start_time =>
        type is 'datetime',
        label is 'Start time',
        filters are qw/ Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime /,
        render as 'unrendered',
        ;

    column stop_time =>
        type is 'datetime',
        label is 'Stop time',
        filters are qw/ Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime /,
        render as 'unrendered',
        ;

    column primary_link =>
        type is 'text',
        label is 'Link',
        ;

    column project =>
        references Qublog::Model::Task,
        label is 'Project',
        since '0.1.0',
        valid_values are defer {
            Qublog::Model::Task->project_none; # make sure it exists
            my $projects = Qublog::Model::TaskCollection->new;
            $projects->limit(
                column => 'task_type',
                value  => 'project',
            );
            $projects->limit(
                column => 'status',
                value  => 'open',
            );
            return [ map { { display => '#'.$_->tag.': '.$_->name, value => $_->id } }
                          @{ $projects->items_array_ref } ];
        },
        ;

    column timers =>
        references Qublog::Model::JournalTimerCollection by 'journal_entry';

    column comments =>
        references Qublog::Model::CommentCollection by 'journal_entry';
};

use Qublog::Mixin::Model::HasOwner;

=head1 TRIGGERS

=head2 before_create

Sets the L</start_time> to right now. Sets the L</journal_day> to today.

=cut

# Your model-specific methods go here.
sub before_create {
    my ($self, $args) = @_;

    $args->{start_time} = Jifty::DateTime->now;
    $args->{journal_day} = Qublog::Model::JournalDay->for_today;

    return 1;
}

=head2 after_create

Starts a L<Qublog::Model::JournalTimer> to be the first timer associated with this entry.

=cut

sub after_create {
    my ($self, $id_ref) = @_;

    return unless $$id_ref;
    $self->load($$id_ref);
    
    $self->start_timer;

    return 1;
}

=head2 before_set_stop_time

If the value is the special string "now" rather than a L<DateTime> object or date formatted string, we convert that to the C<DateTime> object for right now.

=cut

sub before_set_stop_time {
    my ($self, $args) = @_;

    if (defined $args->{value} and $args->{value} eq 'now') {
        $args->{value} = Jifty::DateTime->now;
    }

    return 1;
}

=head1 METHODS

=head2 start_timer

Starts a journal entry by setting the L</stop_time> to C<undef> and creating a new L<Qublog::Model::JournalTimer>. This also stops all other running timers.

=cut

sub start_timer {
    my $self = shift;

    $self->_handle->begin_transaction;

    my $timer;
    eval {
        my $running_entries = Qublog::Model::JournalEntryCollection->new;
        $running_entries->limit_by_running;
        $running_entries->limit(
            column   => 'id',
            operator => '!=',
            value    => $self,
        );

        while (my $running_entry = $running_entries->next) {
            $running_entry->stop_timer;
        }

        $timer = Qublog::Model::JournalTimer->new;
        $timer->create(
            journal_entry => $self,
            start_time    => Jifty::DateTime->now,
        );

        $self->set_stop_time(undef);
    };

    my $ERROR = $@;
    if ($ERROR) {
        eval { $self->_handle->rollback };
        die $ERROR.($@?' '.$@:'');
    }

    $self->_handle->commit;

    return $timer;
}

=head2 stop_timer

This stops the currently running L<Qublog::Model::JournalTimer> objects associated with this entry and sets the L</stop_time> to now.

=cut

sub stop_timer {
    my $self = shift;

    $self->_handle->begin_transaction;

    my $timer;
    eval {
        $timer = Qublog::Model::JournalTimer->new;
        $timer->load_by_cols(
            journal_entry => $self,
            stop_time     => undef,
        );

        my $now = Jifty::DateTime->now;
        $timer->set_stop_time($now);
        $self->set_stop_time($now);
    };

    my $ERROR = $@;
    if ($ERROR) {
        eval { $self->_handle->rollback };
        die $ERROR;
    }

    $self->_handle->commit;

    return $timer;
}

=head2 hours

This returns the total amount of time accumlated by the timers attached to this entry.

=cut

sub hours {
    my ($self, %args) = @_;

    my $hours = 0;
    my $timers = $self->timers;
    $timers->limit_by_running(0) if $args{stopped_only};
    while (my $timer = $timers->next) {
        $hours += $timer->hours;
    }

    return $hours;
}

=head2 current_user_can

The owner can. Everyone else can't.

=cut

sub current_user_can {
    my $self = shift;
    return 1 if defined Jifty->web->current_user->id
            and $self->owner->id == Jifty->web->current_user->id;
    return $self->SUPER::current_user_can(@_);
}


=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

