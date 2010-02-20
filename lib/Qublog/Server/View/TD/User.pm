package Qublog::Server::View::TD::User;

use strict;
use warnings;

use Qublog::Server::Link;
use Qublog::Server::View::Common;

use Template::Declare::Tags;
use Text::Markdown 'markdown';
use Text::Typography 'typography';

=head1 NAME

Qublog::Server::View::TD::User - User-related templates

=head1 DESCRIPTION

The user-related templates for Qublog.

=head1 TEMPLATES

=head2 user/login

Show the login form.

=cut

template 'user/login' => sub {
    my ($self, $c) = @_;

    $c->stash->{title} = 'Hello, Please Sign In';
    $c->add_style( file => 'user/login' );

    page {
        div { { class is 'login-form' }
            form { { action is '/user/login', method is 'POST' }
                my $action = $c->stash->{action};
                $action->unstash('login');
                $action->render;
                $action->results->clear_all;
                $action->stash('login');

                div { { class is 'submit' }
                    $action->render_control(button => {
                        name  => 'submit',
                        label => 'Login',
                    });
                };
            };
        };
    } $c;
};

=head2 user/agreement

Show the license agreement for the user to agree to it.

=cut

template 'user/agreement' => sub {
    my ($self, $c) = @_;
    my $license = $c->stash->{license};

    $c->stash->{title} = $c->config->{'Qublog::Terms'}{agreement_title};

    $c->add_style( file => 'content' );
    $c->add_style( file => 'user/agreement' );

    page { { class is 'content' }
        div { { class is 'terms' }
            outs_raw typography(markdown($license));
        };

        div { { class is 'agreement' }
            form { { method is 'POST', action is '/user/check_agreement' }
                my $action = $c->action_form(schema => 'User::AgreeToTerms' => {
                    record              => $c->user->get_object,
                    agreed_to_terms_md5 => $c->current_terms_md5,
                });
                $action->meta->get_attribute('agreement')->options->{label} = 
                    sprintf('I Agree to the %s.', ucfirst $c->config->{'Qublog::Terms'}{'title'});
                $action->render;
            };
        };
    } $c;
};

=head2 user/logout

Show the user a logout message. (I don't think this is used at the moment.)

=cut

template 'user/logout' => sub {
    my ($self, $c) = @_;

    $c->stash->{title} = 'Good-bye.';

    page {
        p { 'You are now signed out.' };
    } $c;
};

=head2 user/profile

Show the form for editing the user's profile.

=cut

template 'user/profile' => sub {
    my ($self, $c) = @_;
    my $user = $c->stash->{user};

    $c->stash->{title} = 'Your Profile';

    $c->add_style( file => 'user/profile' );
    
    page {
        div { { class is 'profile-form' }

            form { { method is 'POST', action is '/api/model/user/update/profile' }
                my $action = $c->action_form(schema => 'User::Update' => {
                    id     => $c->user->get_object->id,
                    record => $c->user->get_object,
                });
                $action->prefill_from_record;
                $action->setup_and_render(
                    moniker => 'profile',
                    globals => {
                        origin    => $c->request->uri,
                        return_to => $c->request->uri,
                    },
                );

                div { { class is 'submit' }
                    input {
                        type is 'submit',
                        name is 'submit',
                        value is 'Save Changes',
                    };
                };
            };
        };
    } $c;
};

=head2 user/register

Provides the user registration form.

=cut

template 'user/register' => sub {
    my ($self, $c) = @_;

    $c->stash->{title} = 'Registration';

    $c->add_style( file => 'user/register' );

    page {
        div { { class is 'registration-form' }
            form { { method is 'POST', action is '/api/model/user/create/register' }
                
                my $action = $c->action_form(schema => 'User::Create');
                $action->time_zone($c->time_zone);
                $action->setup_and_render(
                    moniker => 'register',
                    globals => {
                        origin    => $c->request->uri,
                        return_to => $c->uri_for('/user/login'),
                    },
                );

                div { { class is 'submit' }
                    $action->render_control(button => {
                        name  => 'submit',
                        label => 'Register',
                    });
                };
            };
        };
    } $c;
};

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
