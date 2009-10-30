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
                label { attr { for => 'username' } 'Login name: ' };
                input {
                    type is 'text',
                    class is 'text',
                    name is 'username',
                    value is $c->request->params->{username} || '',
                };

                label { attr { for => 'password' } 'Password:' };
                input {
                    type is 'password',
                    class is 'password',
                    name is 'password',
                };

                div { { class is 'submit' }
                    input {
                        type is 'hidden',
                        class is 'submit',
                        name is 'next_action',
                        value is '/journal',
                    };

                    input {
                        type is 'submit',
                        class is 'submit',
                        name is 'submit',
                        value is 'Login',
                    };
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
        outs_raw typography(markdown($license));

        div { { class is 'agreement' }
            form { { method is 'POST', action is '/user/check_agreement' }
                input {
                    type is 'submit',
                    name is 'submit',
                    class is 'submit',
                    value is sprintf('I Agree to the %s.', ucfirst $c->config->{'Qublog::Terms'}{'title'}),
                };

                input {
                    type is 'submit',
                    name is 'cancel',
                    class is 'cancel',
                    value is 'I Do Not Agree.',
                };
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

            form { { method is 'POST', action is '/user/update' }
                label { attr { for => 'name' }; 'Name' };
                div { { id is 'name' } $user->name };

                label { attr { for => 'email' }; 'Email Address' };
                input {
                    type is 'text',
                    class is 'text',
                    id is 'email',
                    name is 'email',
                    value is $user->email,
                };

                label { attr { for => 'old_password' }; 'Old Password' };
                input {
                    type is 'password',
                    class is 'password',
                    id is 'old_password',
                    name is 'old_password',
                    value is '',
                };

                label { attr { for => 'password' }; 'New Password' };
                input {
                    type is 'password',
                    class is 'password',
                    id is 'password',
                    name is 'password',
                    value is '',
                };

                label { attr { for => 'confirm_password' }; 'Confirm Password' };
                input {
                    type is 'password',
                    class is 'password',
                    id is 'confirm_password',
                    name is 'confirm_password',
                    value is '',
                };

                label { attr { for => 'time_zone' }; 'Time Zone' };
                select {
                    { id is 'time_zone', name is 'time_zone' }

                    for my $time_zone (DateTime::TimeZone->all_names) {
                        option {
                            if ($time_zone eq $user->time_zone->name) {
                                { selected is 'selected' }
                            }

                            $time_zone;
                        };
                    }
                };

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

    my $fields = $c->field_defaults({
        name      => '',
        email     => '',
        time_zone => $c->config->{time_zone},
    });

    page {
        div { { class is 'registration-form' }
            form { { method is 'POST', action is '/user/create' }
                label { attr { for => 'name' }; 'Name' };
                input {
                    type is 'text',
                    name is 'name',
                    class is 'text',
                    id is 'name',
                    value is $fields->{name},
                };
                
                label { attr { for => 'email' }; 'Email Address' };
                input {
                    type is 'text',
                    class is 'text',
                    id is 'email',
                    name is 'email',
                    value is $fields->{email},
                };

                label { attr { for => 'password' }; 'Password' };
                input {
                    type is 'password',
                    class is 'password',
                    id is 'password',
                    name is 'password',
                };

                label { attr { for => 'confirm_password' }; 'Confirm Password' };
                input {
                    type is 'password',
                    class is 'password',
                    id is 'confirm_password',
                    name is 'confirm_password',
                };

                label { attr { for => 'time_zone' }; 'Time Zone' };
                select {
                    { id is 'time_zone', name is 'time_zone' }

                    for my $time_zone (DateTime::TimeZone->all_names) {
                        option {
                            if ($time_zone eq $fields->{time_zone}) {
                                { selected is 'selected' }
                            }

                            $time_zone;
                        };
                    }
                };

                input {
                    type is 'checkbox',
                    class is 'checkbox',
                    id is 'agreed_to_terms_md5',
                    name is 'agreed_to_terms_md5',
                    value is ,
                };
                label { attr { for => 'agree_to_terms', class => 'checkbox' };
                    my $terms = $c->config->{'Qublog::Terms'};
                    outs sprintf('Do you agree to the %s?', $terms->{title});
                    outs ' (';
                    hyperlink
                        label  => $terms->{label},
                        goto   => $terms->{link},
                        target => '_blank',
                        ;
                    outs ')';
                };

                div { { class is 'submit' }
                    input {
                        type is 'submit',
                        class is 'submit',
                        name is 'submit',
                        value is 'Register',
                    };
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
