use strict;
use warnings;

package Qublog::Model::JournalDay;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::JournalDay - group all the entries and comments for a given day

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

Journals are centered around a journal day. The reason for abstracting this into a special object is that a journal day might at some future point not actually coincide with the 24-hour timeslot. For example, I might be someone that works late and I want my journal entries after midnight to still be included with the previous day's entry.

This also makes it easier to fetch items that belong to a given day.

=head1 SCHEMA

=head2 datestamp

This is the date to associate the journal day object with.

=head2 journal_entries

These are the L<Qublog::Model::JournalEntry> objects that belong to this day.

=head2 comments

These are the L<Qublog::Model::Comment> objects that belong to this day.

=cut

use Qublog::Record schema {
    column datestamp =>
        type is 'date',
        label is 'Date',
        filters are qw/ Jifty::DBI::Filter::Date /,
        is mandatory,
        is distinct,
        is immutable,
        ;

    column journal_entries =>
        references Qublog::Model::JournalEntryCollection by 'journal_day';

    column comments =>
        references Qublog::Model::CommentCollection by 'journal_day';
};

=head1 METHODS

=head2 since

This model was added with the 0.2.0 revision of the database.

=cut

# Your model-specific methods go here.
sub since { '0.2.0' }

=head2 journal_timers

Finds the timers that belong to the associated L</journal_entries>.

=cut

sub journal_timers {
    my $self = shift;

    my $timers = Qublog::Model::JournalTimerCollection->new;
    my $entries_alias = $timers->join(
        column1 => 'journal_entry',
        table2  => Qublog::Model::JournalEntry->table,
        column2 => 'id',
    );
    $timers->limit(
        alias  => $entries_alias,
        column => 'journal_day',
        value  => $self->id,
    );

    return $timers;
}

=head2 for_date DATETIME

This will load or create the L<Qublog::Model::JournalDay> object for the given DATETIME.

=cut

sub for_date {
    my ($self, $date) = @_;
    $self = $self->new unless ref $self;

    my $datestamp = $date->clone->truncate( to => 'day' );

    $self->load_by_cols( datestamp => $datestamp->ymd );
    unless ($self->id) {
        return $self->create( datestamp => $datestamp );
    }

    return $self;
}

=head2 for_today

This will load or create the L<Qublog::Model::JournalDay> object for today.

=cut

sub for_today {
    my $self = shift;
    return $self->for_date( Jifty::DateTime->today );
}

=head2 is_today

Returns true if the current L</datestamp> appears to be today.

=cut

sub is_today {
    my $self = shift;

    return $self->datestamp->ymd eq Jifty::DateTime->today->ymd;
}

=head1 TRIGGERS

=head2 before_create

Makes sure the datestamp is just a datestamp.

=cut

sub before_create {
    my ($self, $args) = @_;

    $args->{datestamp} = $args->{datestamp}->clone->truncate( to => 'day' );

    return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

