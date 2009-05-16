use strict;
use warnings;

package Qublog::Model::RemoteUser;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::RemoteUser - remote user accounts

=head1 SYNOPSIS

  # Please add one

=head1 DESCRIPTION

It is my sincere hope to provide some sort of hosted Qublog site in the very near future. This will provide the glue that helps identify where that server is. I allow for multiple remote users to be configured to make it possible for other hosted Qublog sites to exist.

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

    column site_url =>
        type is 'text',
        label is 'Site URL',
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
    return 1 if defined $self->current_user->id
            and $self->user->id == Jifty->web->current_user->id;
    return $self->SUPER::current_user_can(@_);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

