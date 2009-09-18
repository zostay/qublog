package Qublog::Server::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Qublog::Server::Controller::Root - Root Controller for Qublog::Server

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 begin

Make sure we're logged.

=cut

sub begin :Private {
    my ($self, $c) = @_;
    $c->response->redirect('/user/login') unless $c->user_exists;
}

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/journal/index');
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
