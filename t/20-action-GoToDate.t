#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A test for the GoToDate action.

=cut

use Jifty::Test tests => 4;

# Make sure we can load the action
use_ok('Qublog::Action::GoToDate');

Jifty::Test->web;

my $go_to_date = DateTime->new(
    year => 1999, month => 9, day => 9
);

my $action = Jifty->web->new_action(
    class     => 'GoToDate',
    arguments => { date => $go_to_date },
);
$action->run;

is($action->result->success, 1, 'success');
is(Jifty->web->next_page->url, '/journal', 'go to journal');

my %parameters = Jifty->web->next_page->parameters;
is($parameters{date}, $go_to_date, 'go to 1999-9-9');
