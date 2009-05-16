#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the TaskTag model.

=cut

use lib 't/lib';
use Jifty::Test tests => 14;
use Qublog::Test;
setup_test_user;

# Make sure we can load the model
use_ok('Qublog::Model::TaskTag');

# We need a couple tags and a tasks to test with
my $task1 = Qublog::Model::Task->new;
$task1->create( name => 'foo' );
ok($task1->id);

my $task2 = Qublog::Model::Task->new;
$task2->create( name => 'bar' );
ok($task2->id);

my $tag1 = Qublog::Model::Tag->new;
$tag1->create( name => 'foo' );
ok($tag1->id);

my $tag2 = Qublog::Model::Tag->new;
$tag2->create( name => 'bar' );
ok($tag2->id);

# Try testing a create
my $o = Qublog::Model::TaskTag->new;
my ($id) = $o->create( task => $task1, tag => $tag1 );
ok($id, "TaskTag create returned success");
ok($o->id, "New TaskTag has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create( task => $task2, tag => $tag2 );
ok($o->id, "TaskTag create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  Qublog::Model::TaskTagCollection->new;
$collection->unlimit;
is($collection->count, 5, "Finds five records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 4, "Still four left");

