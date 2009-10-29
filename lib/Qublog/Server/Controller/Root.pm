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

Handles the root namespace, which doesn't actually exist. This controller exists
to forward on requests to either L<Qublog::Server::Controller::Journal> or
L<Qublog::Server::Controller::Content>.

=head1 METHODS

=head2 index

Forwards the user to L<Qublog::Server::Controller::Journal/index>.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/journal/index');
}

=head2 default

Tries the L<Qublog::Server::Controller::Content/index> handler. If that fails,
shows a 404 error.

=cut

sub default :Path {
    my ($self, $c) = @_;

    $c->forward('/content/index');

    unless ($c->stash->{template}) {
        $c->response->body( 'Page not found' );
        $c->response->status(404);
    }
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 LICENSE

Qublog Personal/Professional Journaling
Copyright (C) 2009  Andrew Sterling Hanenkamp

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
