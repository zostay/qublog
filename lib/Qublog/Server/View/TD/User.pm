package Qublog::Server::View::TD::User;

use strict;
use warnings;

use Qublog::Server::Link;
use Qublog::Server::View::Common;
use Template::Declare::Tags;

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

template 'user/logout' => sub {
    my ($self, $c) = @_;

    $c->stash->{title} = 'Good-bye.';

    page {
        p { 'You are now signed out.' };
    } $c;
};

1;
