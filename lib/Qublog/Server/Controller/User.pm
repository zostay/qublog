package Qublog::Server::Controller::User;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Qublog::Server::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Qublog::Server::Controller::User in User.');
}

=head2 login

=cut

sub login :Local {
    my ($self, $c) = @_;

    $c->response->body('TODO Not yet implemented');
}

=head2 register

=cut

sub register :Local {
    my ($self, $c) = @_;

    $c->response->body('TODO Not yet implemented');
}

=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
