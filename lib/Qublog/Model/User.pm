use strict;
use warnings;

package Qublog::Model::User;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::User - a user account

=head1 SYNOPSIS

  # Please add one

=head1 DESCRIPTION

As of Qublog schema version 0.5.0 a single user object is associated with the database.

=head1 SCHEMA

=head2 name

This is the name of the user. It defaults to "me".

=head2 email

This is the email address of the user. This isn't used for anything yet.

=cut

use Qublog::Record schema {
    column name =>
        type is 'text',
        label is 'Name',
        is mandatory,
        is distinct,
        ;

    column email =>
        type is 'text',
        label is 'Email',
        ;

    column email_verified =>
        type is 'bool',
        label is 'Email Verified?',
        is mandatory,
        default is 0,
        ;

    column password =>
        type is 'text',
        label is 'Password',
        render_as 'password',
        is mandatory,
        filters are qw/ Qublog::Filter::SaltHash /,
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
    return 1 if defined Jifty->web->current_user->id
            and $self->id == Jifty->web->current_user->id;
    return $self->SUPER::current_user_can(@_);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

