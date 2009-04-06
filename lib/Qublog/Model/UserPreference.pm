use strict;
use warnings;

package Qublog::Model::UserPreference;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::UserPreference - user preferences stored here

=head1 SYNOPSIS

  # Please add one

=head1 DESCRIPTION

Sometimes it's handy to just to store some generic value that is specific to the user. Those will go here.

=head1 SCHEMA

=head2 user

The user this preference belongs to.

=head2 name

The name of the preference variable. By convention, these are grouped into namespaces separated by a period.

=head2 value

The value of the preference variable.

=cut

use Qublog::Record schema {
    column user =>
        references Qublog::Model::User,
        label is 'User',
        render as 'unrendered',
        is mandatory,
        ;

    column name =>
        type is 'text',
        label is 'Name',
        is mandatory,
        ;

    column value =>
        type is 'text',
        label is 'Value',
        is mandatory,
        ;
};

=head1 METHODS

=head2 since

This class was added in schema version 0.5.0.

=cut

sub since { '0.5.0' }

=head2 current_user_can

The user can. Everyone else can't.

=cut

sub current_user_can {
    my $self = shift;
    my ($op, $args) = @_;
    return 1 if $op eq 'create';
    return 1 if defined Jifty->web->current_user->id
            and $self->user->id == Jifty->web->current_user->id;
    return $self->SUPER::current_user_can(@_);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

