#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A test for the Logout action.

=cut

use lib 't/lib';
use Jifty::Test tests => 5;
use Qublog::Test;
Jifty::Test->web;
my $user = test_user('foobar', 'bazqux');

use_ok('Qublog::Action::Logout');
use_ok('Qublog::Action::Login');

is(Jifty->web->current_user->id, 0, 'no user at start');

{
my $action = Jifty->web->new_action(
    class => 'Login',
    arguments => {
        username => 'foobar',
        password => 'bazqux',
    },
);
$action->run;
}

is(Jifty->web->current_user->id, $user->id, 'user after login');

{
my $action = Jifty->web->new_action(
    class => 'Logout',
);
$action->run;
}

is(Jifty->web->current_user->id, 0, 'no user after logout');
