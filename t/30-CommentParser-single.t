#!/usr/bin/perl
use strict;
use warnings;

require 't/30-CommentParser.pl';
use Test::More tests => 15;

use vars qw( $project );

# Add a simple comment and a single task
{
    my $comment = qq/This is a test.\n\n/;
    my $task    = qq/[ ] Create a new task/;

    my $parser = Qublog::Util::CommentParser->new( 
        project => $project,
        comment => $comment.$task 
    );

    {
        is($parser->comment, $comment.$task, 
            'comment starts matching original');

        my @tasks = $parser->tasks;
        is(scalar @tasks, 0, 'tasks start empty');
    }

    $parser->parse;

    {
        like($parser->comment, qr/\Q$comment\E\s*#5\s*/, 
            'comment is now missing the task');

        my @tasks = $parser->created_tasks;
        my @all_tasks = $parser->tasks;
        is(scalar @tasks, 1, 'found one task created');
        is(scalar @all_tasks, 1, 'found one task');

        is($tasks[0]->tag, '5', 'new tag #5');
        is($tasks[0]->status, 'open', 'open task');
        is($tasks[0]->name, 'Create a new task', 'task name new');
        is($tasks[0]->project->id, $project->id, 'project set');
        is($tasks[0]->parent->id, $project->id, 'parent set');
    }
}

