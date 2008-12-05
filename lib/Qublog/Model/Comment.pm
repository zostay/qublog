use strict;
use warnings;

package Qublog::Model::Comment;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::Comment - Comments attached to a journal

=head1 SYNOPSIS

  # Please write one...

=head1 DESCRIPTION

A journal comment is a comment appended to a particular journal timer and may be linked to one or more tasks.

This class should be named just "Comment" and may be renamed to such in the future.

=head1 SCHEMA

=head2 journal_day

This is the L<Qublog::Model::JournalDay> to which this comment belongs.

=head2 journal_timer

This is the journal timer this comment is associated with, if any.

=head2 name

This is the text of the comment. This is badly named. The name C<subject> or C<description> or something else would be better.

=head2 created_on

This is the date the comment was created on.

=head2 task_logs

This returns a L<TaskLogCollection> for all the task logs that refer to this comment as it's message.

=cut

use Qublog::Record schema {
    column journal_day =>
        references Qublog::Model::JournalDay,
        label is 'Day',
        render as 'unrendered',
        ;

    column journal_timer =>
        references Qublog::Model::JournalTimer,
        label is 'Journal Timer',
        render as 'unrendered',
        ;

    column created_on =>
        type is 'datetime',
        label is 'Time',
        filters are qw/ Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime /,
        ;

    column name =>
        type is 'text',
        label is 'Comment',
        is mandatory,
        render as 'textarea',
        ;

    column task_logs =>
        references Qublog::Model::TaskLogCollection by 'comment';
};

=head1 TRIGGERS

=head2 before_create

Sets the C<created_on> field to now.

=cut

sub before_create {
    my ($self, $args) = @_;

    $args->{created_on} = Jifty::DateTime->now;

    return 1;
}

=head2 before_set_created_on

Allows for time strings to be specified as just the time and makes sure time zones are consistent.

=cut

sub before_set_created_on {
    my ($self, $args) = @_;

    unless (ref $args->{value}) {
        my $dt = Jifty::DateTime->new_from_string(
            $self->journal_day->datestamp->ymd . ' ' . $args->{value}
        );

        $dt = Jifty::DateTime->new_from_string($args->{value})
            unless $dt;

        $args->{value} = $dt;
    }

    return 1;
}

=head1 METHODS

=head2 since

This class was added in DB version 0.2.2. Though, it was renamed from C<Qublog::Model::JournalComment>, which was part of the original core in 0.0.2.

=cut

sub since { '0.2.2' }

=head2 tasks

This returns a L<TaskCollection> for all the tasks linked via the L</task_logs> collection.

=cut

sub tasks {
    my $self = shift;

    my $tasks = Qublog::Model::TaskCollection->new;
    my $log_alias = $tasks->join(
        column1 => 'id',
        table2  => Qublog::Model::TaskLog->table,
        column2 => 'task',
    );
    $tasks->limit(
        alias  => $log_alias,
        column => 'comment',
        value  => $self->id,
    );

    return $tasks;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
