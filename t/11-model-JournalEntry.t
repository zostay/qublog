#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the JournalEntry model.

=cut

use lib 't/lib';
use Jifty::Test tests => 11;
use Qublog::Test;
setup_test_user;

# Make sure we can load the model
use_ok('Qublog::Model::JournalEntry');

# Grab a system user
my $system_user = Qublog::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = Qublog::Model::JournalEntry->new;
my ($id) = $o->create( name => 'test 1' );
ok($id, "JournalEntry create returned success");
ok($o->id, "New JournalEntry has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create( name => 'test 2' );
ok($o->id, "JournalEntry create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  Qublog::Model::JournalEntryCollection->new;
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

