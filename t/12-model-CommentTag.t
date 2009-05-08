#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the CommentTag model.

=cut

use Jifty::Test tests => 14;

# Make sure we can load the model
use_ok('Qublog::Model::CommentTag');

# Grab a system user
my $system_user = Qublog::CurrentUser->superuser;
ok($system_user, "Found a system user");

my $comment = Qublog::Model::Comment->new(current_user => $system_user);
$comment->create( 
    journal_day => Qublog::Model::JournalDay->for_today,
    name        => 'This is some comment',
);
ok($comment->id, 'got a comment');

my $tag1 = Qublog::Model::Tag->new(current_user => $system_user);
$tag1->create( name => 'tag1' );
ok($tag1->id, 'got tag1');

my $tag2 = Qublog::Model::Tag->new(current_user => $system_user);
$tag2->create( name => 'tag2' );
ok($tag2->id, 'got tag2');

# Try testing a create
my $o = Qublog::Model::CommentTag->new(current_user => $system_user);
my ($id) = $o->create( comment => $comment, tag => $tag1 );
ok($id, "CommentTag create returned success");
ok($o->id, "New CommentTag has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create( comment => $comment, tag => $tag2 );
ok($o->id, "CommentTag create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  Qublog::Model::CommentTagCollection->new(current_user => $system_user);
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

