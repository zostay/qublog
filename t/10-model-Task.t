#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the Task model.

=cut

use lib 't/lib';
use Jifty::Test tests => 10;
use Qublog::Test;
setup_test_user;

# Make sure we can load the model
use_ok('Qublog::Model::Task');

# Try testing a create
my $o = Qublog::Model::Task->new;
my ($id) = $o->create( name => 'Task 1' );
ok($id, "Task create returned success");
ok($o->id, "New Task has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create( name => 'Task 2' );
ok($o->id, "Task create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  Qublog::Model::TaskCollection->new;
$collection->unlimit;
is($collection->count, 3, "Finds three records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 2, "Still two left");

