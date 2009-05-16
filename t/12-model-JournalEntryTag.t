#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the JournalEntryTag model.

=cut

use lib 't/lib';
use Jifty::Test tests => 13;
use Qublog::Test;
setup_test_user;

# Make sure we can load the model
use_ok('Qublog::Model::JournalEntryTag');

my $entry = Qublog::Model::JournalEntry->new;
$entry->create( name => 'Some Entry' );
ok($entry->id, 'got a journal entry');

my $tag1 = Qublog::Model::Tag->new;
$tag1->create( name => 'tag1' );
ok($tag1->id, 'got tag1');

my $tag2 = Qublog::Model::Tag->new;
$tag2->create( name => 'tag2' );
ok($tag2->id, 'got tag2');

# Try testing a create
my $o = Qublog::Model::JournalEntryTag->new;
my ($id) = $o->create( journal_entry => $entry, tag => $tag1 );
ok($id, "JournalEntryTag create returned success");
ok($o->id, "New JournalEntryTag has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create( journal_entry => $entry, tag => $tag2 );
ok($o->id, "JournalEntryTag create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  Qublog::Model::JournalEntryTagCollection->new;
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

