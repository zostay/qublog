#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the User model.

=cut

use Jifty::Test tests => 17;

# Make sure we can load the model
use_ok('Qublog::Model::User');

# Grab a system user
my $system_user = Qublog::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = Qublog::Model::User->new(current_user => $system_user);
my ($id) = $o->create( name => 'foo', password => 'secret' );
ok($id, "User create returned success");
ok($o->id, "New User has valid id set");
is($o->id, $id, "Create returned the right id");
is($o->name, 'foo', 'Created user name is foo');
isnt("".$o->password, 'secret', 'Password does not stringify and match');
ok($o->password eq 'secret', 'Password matches');

# And another
$o->create( name => 'bar', password => 'VERY-secret' );
ok($o->id, "User create returned another value");
isnt($o->id, $id, "And it is different from the previous one");
is($o->name, 'bar', 'Created user name is bar');
isnt("".$o->password, 'VERY-secret', 'Password does not stringify and match');
ok($o->password eq 'VERY-secret', 'Password matches');

# Searches in general
my $collection =  Qublog::Model::UserCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 1, "Still one left");

