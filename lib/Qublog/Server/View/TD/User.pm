package Qublog::Server::View::TD::User;
use Moose;

use Qublog::Server::View::Common;
use Template::Declare::Tags;

template 'user/login' => sub {
    my ($self, $c) = @_;

    $c->stash->{title} = 'Hello';

    page {
        form { { action is '/user/login', method is 'POST' }
            label { attr { for => 'username' } 'Login name: ' };
            input {
                type is 'text',
                name is 'username',
                value is $c->request->params->{username} || '',
            };

            label { attr { for => 'password' } 'Password:' };
            input {
                type is 'password',
                name is 'password',
            };

            input {
                type is 'hidden',
                name is 'next_action',
                value is '/journal',
            };

            input {
                type is 'submit',
                name is 'submit',
                value is 'Login',
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
