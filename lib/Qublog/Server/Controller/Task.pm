package Qublog::Server::Controller::Task;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Qublog::Server::Controller::Task - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $user = $c->user->get_object;

    $c->stash->{task_filter} = $c->model('DB::Task')->search_current($user);
    $c->stash->{projects}    = $c->stash->{task_filter}->search({
        task_type => 'project',
    });

    $c->stash->{template} = '/task/index';
}


=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
