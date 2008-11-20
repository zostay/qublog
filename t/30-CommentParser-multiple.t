#!/usr/bin/perl
use strict;
use warnings;

require 't/30-CommentParser.pl';
use Test::More tests => 25;

use vars qw( $project );

# Add a comment and three more complex tasks
{
    my $comment = qq/This is a test.\n\n/;
    my @tasks   = (
        qq/[x] Create a done task/,
        qq/ [!]   #testing: Create a nixed task/,
        qq/[-] Create a task without a specified status /,
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
        like($parser->comment, qr/\Q$comment\E\s*#5\s*#testing\s*#8\s*/, 
            'comment is now missing the tasks');

        my @task_objs = $parser->created_tasks;
        my @all_tasks = $parser->tasks;
        is(scalar @task_objs, scalar @tasks, 'found three tasks created');
        is(scalar @task_objs, scalar @all_tasks, 'found three tasks');

        is($task_objs[0]->tag, '5', 'new tag #5');
        is($task_objs[0]->status, 'done', 'done task');
        is($task_objs[0]->name, 'Create a done task', 'task name done');
        is($task_objs[0]->project->id, $project->id, 'project set');
        is($task_objs[0]->parent->id, $project->id, 'parent set');

        is($task_objs[1]->tag, 'testing', 'new tag #testing');
        is($task_objs[1]->status, 'nix', 'nixed task');
        is($task_objs[1]->name, 'Create a nixed task', 'task name nixed');
        is($task_objs[1]->project->id, $project->id, 'project set');
        is($task_objs[1]->parent->id, $project->id, 'parent set');

        is($task_objs[2]->tag, '8', 'new tag #8');
        is($task_objs[2]->status, 'open', 'open task');
        is($task_objs[2]->name, 'Create a task without a specified status', 
            'task name unspecified');
        is($task_objs[2]->project->id, $project->id, 'project set');
        is($task_objs[2]->parent->id, $project->id, 'parent set');
    }
}

