use strict;
use warnings;

package Qublog::Model::TaskChange;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::TaskChange - tracks a specific change to a task

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

Each L<Qublog::Model::Task> has a history, which is tracked through the L<Qublog::Model::TaskLog> objects attached to it. Each of these, in turn, have one or more L<Qublog::Model::TaskChange> objects attached to note individual field updates.

=head1 SCHEMA

=head2 task_log

This is the L<Qublog::Model::TaskLog> to which this change belongs.

=head2 name

This is the name of the L<Qublog::Model::Task> field that has changed.

=head2 old_value

This is a copy of the old value the field had prior to the change.

=head2 new_value

This is a copy of the new value the field has been changed to.

=cut

use Qublog::Record schema {
    column task_log =>
        references Qublog::Model::TaskLog,
        label is 'Task log',
        is mandatory,
        is immutable,
        ;

    column name =>
        type is 'text',
        label is 'Field name',
        is mandatory,
        is immutable,
        ;

    column old_value =>
        type is 'text',
        label is 'Old value',
        is immutable,
        ;

    column new_value =>
        type is 'text',
        label is 'New value',
        is mandatory,
        default is '',
        is immutable,
        ;
};

=head1 METHODS

=head2 since

This class was added with the 0.1.4 database revision.

=cut

sub since { '0.1.4' }

=head2 owner

This change has the same owner as the task log it belongs to.

=cut

sub owner {
    shift->task_log->owner;
}

=head2 current_user_can

The owner can. Everyone else can't.

=cut

sub current_user_can {
    my $self = shift;
    return 1 if $self->owner->id = Jifty->web->current_user->id;
    return $self->SUPER::current_user_can(@_);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

