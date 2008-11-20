#!/usr/bin/perl
use strict;
use warnings;

require 't/30-CommentParser.pl';
use Test::More tests => 40;

use vars qw( $project );

# Add a comment and six nested tasks
{
    my $comment = qq/This is a test.\n\n/;
    my @tasks   = (
        qq/[ ] Task 1/,
        qq/[ ] Task 2/,
        qq/-[ ] Task 2A/,
        qq/--[ ] Task 2Ai/,
        qq/-[ ] Task 2B/,
        qq/-[ ] Task 2C/,
    );
    my $joined_tasks = join "\n", @tasks;

    my $parser = Qublog::Util::CommentParser->new( 
        project => $project,
        comment => $comment.$joined_tasks
    );

    {
        is($parser->comment, $comment.$joined_tasks, 
            'comment starts matching original');

        my @tasks = $parser->tasks;
        is(scalar @tasks, 0, 'tasks start empty');
    }

    $parser->parse;

    {
        like($parser->comment, 
            qr/\Q$comment\E\s*#5\s*#6\s*#7\s*#8\s*#9\s*#A\s*/, 
            'comment is now missing the tasks');

        my @task_objs = $parser->created_tasks;
        my @all_tasks = $parser->tasks;
        is(scalar @task_objs, scalar @tasks, 'found three tasks created');
        is(scalar @task_objs, scalar @all_tasks, 'found three tasks');

        is($task_objs[0]->tag, '5', 'new tag #5');
        is($task_objs[0]->status, 'open', 'open task');
        is($task_objs[0]->name, 'Task 1', 'comment Task 1');
        is($task_objs[0]->parent->id, $project->id, 'Task 1 parent is set');
        is($task_objs[0]->project->id, $project->id, 'Task 1 project is set');

        is($task_objs[1]->tag, '6', 'new tag #6');
        is($task_objs[1]->status, 'open', 'open task');
        is($task_objs[1]->name, 'Task 2', 'comment Task 2');
        is($task_objs[1]->parent->id, $project->id, 'Task 2 parent is set');
        is($task_objs[1]->project->id, $project->id, 'Task 2 project is set');

        is($task_objs[2]->tag, '7', 'new tag #7');
        is($task_objs[2]->status, 'open', 'open task');
        is($task_objs[2]->name, 'Task 2A', 'comment Task 2A');
        is($task_objs[2]->parent->id, $task_objs[1]->id, 
            'Task 2A parent is Task 2');
        is($task_objs[2]->project->id, $project->id, 'Task 2A project is set');

        is($task_objs[3]->tag, '8', 'new tag #8');
        is($task_objs[3]->status, 'open', 'open task');
        is($task_objs[3]->name, 'Task 2Ai', 'comment Task 2Ai');
        is($task_objs[3]->parent->id, $task_objs[2]->id, 
            'Task 2Ai parent is Task 2A');
        is($task_objs[3]->project->id, $project->id, 
            'Task 2Ai project is set');

        is($task_objs[4]->tag, '9', 'new tag #9');
        is($task_objs[4]->status, 'open', 'open task');
        is($task_objs[4]->name, 'Task 2B', 'comment Task 2B');
        is($task_objs[4]->parent->id, $task_objs[1]->id, 
            'Task 2B parent is Task 2');
        is($task_objs[4]->project->id, $project->id, 'Task 2B project is set');

        is($task_objs[5]->tag, 'A', 'new tag #A');
        is($task_objs[5]->status, 'open', 'open task');
        is($task_objs[5]->name, 'Task 2C', 'comment Task 2C');
        is($task_objs[5]->parent->id, $task_objs[1]->id, 
            'Task 2C parent is Task 2');
        is($task_objs[5]->project->id, $project->id, 'Task 2C project is set');
    }
}

