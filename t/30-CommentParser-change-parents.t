#!/usr/bin/perl
use strict;
use warnings;

require 't/30-CommentParser.pl';
use Test::More tests => 30;

use vars qw( $project );

# Try a simple parent set
{
    {
        my $comment = qq/This is a test.\n\n/;
        my $task    = qq/[ ] #foo: Create a new task\n/;
           $task   .= qq/[ ] #bar: Another new task/;

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
            my @tasks = $parser->created_tasks;
            my @all_tasks = $parser->tasks;
            is(scalar @tasks, 2, 'found two tasks created');
            is(scalar @all_tasks, 2, 'found two tasks');

            is($tasks[0]->tag, 'foo', 'new tag #foo');
            is($tasks[0]->status, 'open', 'open task');
            is($tasks[0]->name, 'Create a new task', 'task name new');
            is($tasks[0]->project->id, $project->id, 'project set');
            is($tasks[0]->parent->id, $project->id, 'parent set');

            is($tasks[1]->tag, 'bar', 'new tag #bar');
            is($tasks[1]->status, 'open', 'open task');
            is($tasks[1]->name, 'Another new task', 'task name new');
            is($tasks[1]->project->id, $project->id, 'project set');
            is($tasks[1]->parent->id, $project->id, 'parent set');
        }
    }

    {
        my $rearrange_tasks = qq/[-] #foo\n-[-] #bar/;
        my $parser = Qublog::Util::CommentParser->new(
            project => $project,
            comment => $rearrange_tasks,
        );

        $parser->parse;

        my @tasks = $parser->updated_tasks;
        is(scalar @tasks, 2, 'found two tasks');

        is($tasks[0]->tag, 'foo', 'updated tag #foo');
        is($tasks[0]->status, 'open', 'open task');
        is($tasks[0]->name, 'Create a new task', 'task is same');
        is($tasks[0]->project->id, $project->id, 'project set');
        is($tasks[0]->parent->id, $project->id, 'parent set');

        is($tasks[1]->tag, 'bar', 'updated tag #bar');
        is($tasks[1]->status, 'open', 'open task');
        is($tasks[1]->name, 'Another new task', 'task is isame');
        is($tasks[1]->project->id, $project->id, 'project same');
        is($tasks[1]->parent->id, $tasks[0]->id, 'parent changed');
    }
}
