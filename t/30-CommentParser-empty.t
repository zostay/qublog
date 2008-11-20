#!/usr/bin/perl
use strict;
use warnings;

require 't/30-CommentParser.pl';
use Test::More tests => 16;

# Simple test of the class using an empty comment
{
    my $parser = Qublog::Util::CommentParser->new( comment => '' );

    can_ok($parser, 'project');
    can_ok($parser, 'comment');
    can_ok($parser, 'created_tasks');
    can_ok($parser, 'updated_tasks');
    can_ok($parser, 'linked_tasks');
    can_ok($parser, 'tasks');
    can_ok($parser, 'parse');

    {
        is($parser->comment, '', 'comment start empty');

        my @tasks = $parser->tasks;
        is(scalar @tasks, 0, 'tasks start empty');
    }

    $parser->parse;

    {
        is($parser->comment, '', 'comment still empty');

        my @tasks = $parser->tasks;
        is(scalar @tasks, 0, 'tasks still empty');
    }
}

