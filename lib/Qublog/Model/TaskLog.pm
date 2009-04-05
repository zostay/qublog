use strict;
use warnings;

package Qublog::Model::TaskLog;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::TaskLog - a log of changes to a task

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

Each L<Qublog::Model::Task> tracks it's history through task log objects. Each task log object is a message with a number of L<Qublog::Model::TaskChange> objects describing individual field updates.

=head1 SCHEMA

=head2 task

This is the L<Qublog::Model::Task> to which this log belongs.

=head2 log_type

This describes the type of log message this is. It is one of the following:

=over

=item create

Each task should have exactly one of these. This gives information about the task's creation.

=item update

Every time a field is updated on a task, one of these logs is added.

=item note

This is used to indicate that a L</comment> is present and is generally used for any non-create/non-update change.

=back

=head2 created_on

This is the timestamp the logged action took place.

=head2 message

DEPRECATED. Removed in 0.2.4 and was never used.

=head2 comment

This is the comment attached to the logged action.

=cut

use Qublog::Record schema {
    column task =>
        references Qublog::Model::Task,
        label is 'Task',
        is mandatory,
        is immutable,
        ;

    column log_type =>
        type is 'text',
        label is 'Type',
        valid_values are qw/ 
            create
            update
            note
        /,
        is mandatory,
        ;

    column created_on =>
        type is 'datetime',
        label is 'Created on',
        is mandatory,
        filters are qw/ Jifty::Filter::DateTime Jifty::DBI::Filter::DateTime /,
        ;

    column message =>
        type is 'text',
        label is 'Message',
        till '0.2.4',
        ;

    column comment =>
        references Qublog::Model::Comment,
        label is 'Message',
        since '0.2.4',
        ;

    column task_changes =>
        references Qublog::Model::TaskChangeCollection by 'task_log';
};

use Qublog::Mixin::Model::HasOwner;

=head1 METHODS

=head2 since

This model was added with the 0.1.4 database revision.

=cut

sub since { '0.1.4' }

=head2 current_user_can

The owner can. Everyone else can't.

=cut

sub current_user_can {
    my $self = shift;
    return 1 if $self->owner->id == Jifty->web->current_user->id;
    return $self->SUPER::current_user_can(@_);
}

=head1 TRIGGERS

=head2 before_create

Sets the L</created_on> timestamp.

=cut

sub before_create {
    my ($self, $args) = @_;

    $args->{created_on} ||= Jifty::DateTime->now;

    return 1;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

