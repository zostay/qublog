use strict;
use warnings;

package Qublog::Model::JournalTimer;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::JournalTimer - a span of time focused on a particular task

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

Groups a set of comments together and times a segment of time spent working on a particular task.

=head1 SCHEMA

=head2 journal_entry

This is the journal entry to which tihs timer belongs to. This is used to group similar timers together.

=head2 start_time

This is the time the timer started.

=head2 stop_time

This is the time the timer stopped.

=head2 comments

This is the collection of L<Qublog::Model::Comment> objects that belong with this timer.

=cut

use Qublog::TimedRecord schema {
    column journal_entry =>
        references Qublog::Model::JournalEntry,
        label is 'Journal Entry',
        is mandatory,
        ;

    column start_time =>
        type is 'datetime',
        label is 'Start time',
        filters are qw/ Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime /,
        ;

    column stop_time =>
        type is 'datetime',
        label is 'Stop time',
        filters are qw/ Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime /,
        ;

    column comments =>
        references Qublog::Model::CommentCollection by 'journal_timer';
};

=head1 METHODS

=head2 since

This class was added in 0.1.2.

=cut

# Your model-specific methods go here.
sub since { '0.1.2' }

=head2 hours [ stopped_only => 1 ]

Returns a decimal representing the number of hours spent on this timer (including fractional hours).

The optional C<stopped_only> option will cause C<hours> to return 0 if given and this timer is running (see L<Qublog::TimedRecord/is_running>.

=cut

sub hours {
    my ($self, %args) = @_;

    return 0 if $args{stopped_only} and $self->is_running;

    my $start_time = $self->start_time;
    my $stop_time  = $self->stop_time || Jifty::DateTime->now;

    my $duration = $stop_time - $start_time;
    return $duration->delta_months  * 720 # assume, 30 day months... craziness
         + $duration->delta_days    * 24  # still a stretch
         + $duration->delta_minutes / 60
         + $duration->delta_seconds / 3600
         ;
}

=head1 SEE ALSO

L<Qublog::TimedRecord>

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

