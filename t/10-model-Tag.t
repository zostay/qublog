#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the Tag model.

=cut

use Jifty::Test tests => 11;

# Make sure we can load the model
use_ok('Qublog::Model::Tag');

# Grab a system user
my $system_user = Qublog::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = Qublog::Model::Tag->new(current_user => $system_user);
my ($id) = $o->create( name => 'foo' );
ok($id, "Tag create returned success");
ok($o->id, "New Tag has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create( name => 'bar' );
ok($o->id, "Tag create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  Qublog::Model::TagCollection->new(current_user => $system_user);
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

