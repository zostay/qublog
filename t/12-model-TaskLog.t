#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the TaskLog model.

=cut

use lib 't/lib';
use Jifty::Test tests => 12;
use Qublog::Test;
setup_test_user;

# Make sure we can load the model
use_ok('Qublog::Model::Task');
use_ok('Qublog::Model::TaskLog');

# Get the default task for testing
my $task = Qublog::Model::Task->project_none;

# Check to make sure the initial user exists
my $collection =  Qublog::Model::TaskLogCollection->new;
$collection->unlimit;
is($collection->count, 1, "Finds one record from creating the none project");

# Try testing a create
my $o = Qublog::Model::TaskLog->new;
my ($id) = $o->create(
    task     => $task,
    log_type => 'note',
);
ok($id, "TaskLog create returned success");
ok($o->id, "New TaskLog has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create(
    task     => $task,
    log_type => 'note',
);
ok($o->id, "TaskLog create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
$collection =  Qublog::Model::TaskLogCollection->new;
$collection->unlimit;
is($collection->count, 3, "Finds three records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds two record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 2, "Still two left");

