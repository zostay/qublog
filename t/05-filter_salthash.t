#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';
use Jifty::Test tests => 8;

my $su = Qublog::CurrentUser->superuser;
ok($su, 'got a system user');

my $rec = Qublog::Model::TestUser->new( current_user => $su );
isa_ok($rec, 'Jifty::DBI::Record');

my ($id) = $rec->create( password => 'very-very-secret' );
ok($id, 'created record');
ok($rec->load($id), 'loaded record');
is($rec->id, $id, 'record id matches');
isa_ok($rec->password, 'Qublog::Filter::SaltHash::Value');
ok($rec->password eq 'very-very-secret', 'password matches encoding');

# undef/NULL
$rec->set_password;
is($rec->password, undef, 'set undef value');

