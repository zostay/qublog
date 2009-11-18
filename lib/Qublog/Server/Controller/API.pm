package Qublog::Server::Controller::API;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Qublog::Util qw( class_name_from_name );

=head1 NAME

Qublog::Server::Controller::API - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 model

=cut

sub model :Local :Args(3) {
    my ($self, $c, $model, $do, $moniker) = @_;

    my $name = join('::', map { class_name_from_name($_) } ($model, $do));
    my $action = $c->action_form(schema => $name);
    $action->unstash($moniker) if $moniker;
    $action->clean_and_check_and_process;

    if ($action->is_valid and $action->is_success) {
        if ($action->globals->{return_to}) {
            $c->response->redirect($action->globals->{return_to});
        }
        else {
            $c->response->body(join "\n", @{ $action->messages });
        }
    }
    else {
        $action->stash($moniker) if $moniker;

        if ($action->globals->{origin}) {
            $c->response->redirect($action->globals->{origin});
        }
        else {
            $c->response->body(join "\n", @{ $action->messages });
        }
    }
}


=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
