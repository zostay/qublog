package Qublog::Server::Controller::User;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use DateTime::TimeZone;
use Email::Valid;
use File::Slurp qw( read_file );
use List::MoreUtils qw( none );

=head1 NAME

Qublog::Server::Controller::User - User management for Qublog

=head1 DESCRIPTION

You must have a user account to do anything interesting in Qublog. This helps
you do that.

=head1 METHODS

=head2 index

Isn't really meant to be used. However, if you go here, you will either be sent
to the login screen (if you are not logged yet) or you will be sent to the
profile screen.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    if ($c->user_exists) {
        $c->forward('profile');
    }
    else {
        $c->forward('login');
    }
}

=head2 check

Private method for checking to make sure the user is logged and agrees to the
latest terms.

=cut

sub check :Private {
    my ($self, $c) = @_;

    unless ($c->user_exists) {
        $c->response->redirect('/user/login');
        return $c->detach;
    }

    my $current_terms = $c->current_terms_md5;
    unless ($current_terms) {
        warn "LICENSE FILE IS MISSING!!!";
        return;
    }

    my $user = $c->user->get_object;
    my $agreed_to = $user->agreed_to_terms_md5;
    if (not $agreed_to or $agreed_to ne $current_terms) {
        my $message = 'the %s has changed.';
        $message = 'you must agree to the %s.' if not $agreed_to;
        $message .= ' Please read the following and select an action below to continue';

        push @{ $c->flash->{messages} }, {
            type    => 'warning',
            message => sprintf($message, $c->config->{'Qublog::Terms'}{title}),
        };

        $c->response->redirect('/user/agreement');
        return $c->detach;
    }
}

=head2 login

Present a login form to the user and/or process such a login.

=cut

sub login :Local {
    my ($self, $c) = @_;

    my $action = $c->action_form(server => 'Login');
    $action->unstash('login');
    my $submitted = $action->consume_control(button => {
        name  => 'submit',
        label => 'Login',
    }, request => $c->request);

    if ($submitted->is_true) {
        $action->consume_and_clean_and_check_and_process( request => $c->request );

        $c->result_to_messages($action->results);

        if ($action->is_valid and $action->is_success) {
            $c->response->redirect($c->uri_for(
                $action->globals->{next_action} || '/journal'
            ));
        }
        else {
            $action->stash('login');
        }
    }

    $c->stash->{action}   = $action;
    $c->stash->{template} = '/user/login';
}

=head2 agreement

Ask the user to agree to the terms of the license.

=cut

sub agreement :Local {
    my ($self, $c) = @_;

    $c->detach('default') unless $c->user_exists;

    my $license_file = $c->config->{'Qublog::Terms'}{'file'};
    my $license_path = $c->path_to('root', 'content', $license_file);

    $c->stash->{license}  = read_file("$license_path");
    $c->stash->{user}     = $c->user->get_object;
    $c->stash->{template} = '/user/agreement';
}

=head2 check_agreement

If the user agrees, mark that, if not boot them.

=cut

sub check_agreement :Local {
    my ($self, $c) = @_;

    $c->detach('default') unless $c->user_exists;

    my $title = $c->config->{'Qublog::Terms'}{title};

    my $action = $c->action_form(schema => 'User::AgreeToTerms', {
        record              => $c->user->get_object,
        agreed_to_terms_md5 => $c->current_terms_md5,
    });

    $action->consume_and_clean_and_check_and_process( request => $c->request );
    if ($action->is_valid and not $action->is_success) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => sprintf('logging you out. You may not use Qublog unless you agree to the %s', $title),
        };
        $c->detach('logout');
    }
    elsif (not $action->is_valid) {
        $c->response->redirect('/user/agreement');
    }
    else {
        $c->response->redirect('/journal');
    }
}

=head2 logout

Log the user out of the site.

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

Show a registration form to the user.

=cut

sub register :Local {
    my ($self, $c) = @_;

    $c->stash->{template} = '/user/register';
}

=head2 profile

Show a profile editor for the user.

=cut

sub profile :Local {
    my ($self, $c) = @_;

    $c->forward('check');

    $c->stash->{user}     = $c->user->get_object;
    $c->stash->{template} = '/user/profile';
}

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
