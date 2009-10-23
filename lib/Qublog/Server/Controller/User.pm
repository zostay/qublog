package Qublog::Server::Controller::User;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use DateTime::TimeZone;
use Email::Valid;
use List::MoreUtils qw( none );

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

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => 'you have signed out',
    };

    $c->response->redirect('/user/login');
}

=head2 register

=cut

sub register :Local {
    my ($self, $c) = @_;

    $c->stash->{template} = '/user/register';
}

=head2 profile

=cut

sub profile :Local {
    my ($self, $c) = @_;

    $c->stash->{user}     = $c->user->get_object;
    $c->stash->{template} = '/user/profile';
}

=head2 update

Save the current user's profile information.

=cut

sub update :Local {
    my ($self, $c) = @_;
    my $user = $c->user->get_object;

    my $email = $c->request->params->{email};
    unless (Email::Valid->address($email)) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'the email address you typed does not look right',
        };
        return $c->detach('/user/profile');
    }

    my $time_zone = $c->request->params->{time_zone};
    if (none { $_ eq $time_zone } DateTime::TimeZone->all_names) {
        push @{ $c->flash->{time_zone} }, {
            type    => 'error',
            message => 'please select a time zone',
        };
        return $c->detach('/user/profile');
    }

    $time_zone = DateTime::TimeZone->new( name => $time_zone );

    my $old_password     = $c->request->params->{old_password};
    my $password         = $c->request->params->{password};
    my $confirm_password = $c->request->params->{confirm_password};

    if ($old_password or $password or $confirm_password) {
        unless ($old_password) {
            push @{ $c->flash->{messages} }, {
                type    => 'error',
                message => 'please type your current password in the Old Password box too',
            };
            return $c->detach('/user/profile');
        }

        unless ($password) {
            push @{ $c->flash->{messages} }, {
                type    => 'error',
                message => 'please type your new password in the Password box too',
            };
            return $c->detach('/user/profile');
        }

        unless ($confirm_password) {
            push @{ $c->flash->{messages} }, {
                type    => 'error',
                message => 'please type your new password again in the Confirm Password box',
            };
            return $c->detach('/user/profile');
        }

        unless (length($password) >= 6) {
            push @{ $c->flash->{messages} }, {
                type    => 'error',
                message => 'your password must be at least 6 characters long',
            };
            return $c->detach('/user/profile');
        }

        unless ($user->check_password($old_password)) {
            push @{ $c->flash->{messages} }, {
                type    => 'error',
                message => 'sorry, the password you gave does not match your current password',
            };
            return $c->detach('/user/profile');
        }

        unless ($password eq $confirm_password) {
            push @{ $c->flash->{messages} }, {
                type    => 'error',
                message => 'the new passwords you entered do not match, please try again',
            };
            return $c->detach('/user/profile');
        }

        $user->change_password($password);
    }

    $user->email($email);
    $user->time_zone($time_zone);
    $user->update;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => 'updated your profile',
    };

    return $c->response->redirect('/user/profile');
}

=head2 new

Register a new user.

=cut

sub create :Local {
    my ($self, $c) = @_;

    $c->model('DB')->txn_do(sub {

    my $name = $c->request->params->{name};
    unless ($name) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'please give a name to use as your login name',
        };
        return $c->detach('/user/register');
    }

    $name =~ s/^\s+//; $name =~ s/\s+$//;
    unless (length $name >= 3) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'your login name must be at least 3 characters long',
        };
        return $c->detach('/user/register');
    }

    if ($name =~ /[^\w\ '\-]/) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'your login name may only contain letters, numbers, spaces, apostrophes, and hyphens',
        };
        return $c->detach('/user/register');
    }

    if ($c->model('DB::User')->find({ name => $name })) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'sorry, that name is already in use',
        };
        return $c->detach('/user/register');
    }

    my $email = $c->request->params->{email};
    unless (Email::Valid->address($email)) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'the email address you typed does not look right',
        };
        return $c->detach('/user/register');
    }

    my $time_zone = $c->request->params->{time_zone};
    if (none { $_ eq $time_zone } DateTime::TimeZone->all_names) {
        push @{ $c->flash->{time_zone} }, {
            type    => 'error',
            message => 'please select a time zone',
        };
        return $c->detach('/user/register');
    }

    $time_zone = DateTime::TimeZone->new( name => $time_zone );

    my $password         = $c->request->params->{password};
    my $confirm_password = $c->request->params->{confirm_password};

    unless ($password) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'please type your password in the Password box',
        };
        return $c->detach('/user/register');
    }

    unless ($confirm_password) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'please type your password again in the Confirm Password box',
        };
        return $c->detach('/user/register');
    }

    unless (length($password) >= 6) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'your password must be at least 6 characters long',
        };
        return $c->detach('/user/register');
    }

    unless ($password eq $confirm_password) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'the passwords you entered do not match, please try again',
        };
        return $c->detach('/user/register');
    }

    my $user = $c->model('DB::User')->create({
        name      => $name,
        email     => $email,
        password  => '*',
        time_zone => $time_zone,
    });
    $user->change_password($password);
    $user->update;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => 'created your profile, you may now sign in',
    };

    });

    return $c->response->redirect('/user/login');
}
=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
