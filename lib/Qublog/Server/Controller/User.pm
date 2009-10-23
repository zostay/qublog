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

=head2 begin

Cancel the actions of the root begin, which redirects without a user.

=cut

sub begin :Private { }


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

    if ($c->request->params->{submit} eq 'Login') {
        my $username    = $c->request->params->{username};
        my $password    = $c->request->params->{password};
        my $next_action = $c->request->params->{next_action} || '/journal';

        if ($username and $password) {
            if ($c->authenticate({ name => $username, password => $password })) {
                push @{ $c->flash->{messages} }, {
                    type    => 'info',
                    message => sprintf('welcome back, %s', $username),
                };

                $c->response->redirect($c->uri_for($next_action));
            }
            else {
                push @{ $c->flash->{messages} }, {
                    type    => 'error',
                    message => 'no account matches that username and password',
                };
            }
        }

        if (not $username) {
            push @{ $c->flash->{messages} }, {
                type    => 'error',
                field   => 'username',
                message => 'please enter a username',
            };
        }        

        if (not $password) {
            push @{ $c->flash->{messages} }, {
                type    => 'error',
                field   => 'password',
                message => 'please enter a password',
            };
        }
    }

    $c->stash->{template} = '/user/login';
}

=head2 logout

=cut

sub logout :Local {
    my ($self, $c) = @_;
    $c->logout();
    $c->stash->{template} = '/user/logout';
}

=head2 register

=cut

sub register :Local {
    my ($self, $c) = @_;

    $c->response->body('TODO Not yet implemented');
}

=head2 profile

=cut

sub profile :Local {
    my ($self, $c) = @_;

    $c->stash->{user}     = $c->user->get_object;
    $c->stash->{template} = '/user/profile';
}

=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
