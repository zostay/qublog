#!/usr/bin/perl
use strict;
use warnings;

use Jifty::Everything;
Jifty->new;

use Test::MockModule;
use Test::More tests => 93;
use Jifty::Test;

Jifty::Test->web;
use_ok('Qublog::Util::CommentParser');

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

# Add a simple comment and a single task
{
    my $comment = qq/This is a test.\n\n/;
    my $task    = qq/[ ] Create a new task/;

    my $parser = Qublog::Util::CommentParser->new( comment => $comment.$task );

    {
        is($parser->comment, $comment.$task, 
            'comment starts matching original');

        my @tasks = $parser->tasks;
        is(scalar @tasks, 0, 'tasks start empty');
    }

    $parser->parse;

    {
        like($parser->comment, qr/\Q$comment\E\s*#4\s*/, 
            'comment is now missing the task');

        my @tasks = $parser->created_tasks;
        my @all_tasks = $parser->tasks;
        is(scalar @tasks, 1, 'found one task created');
        is(scalar @all_tasks, 1, 'found one task');

        is($tasks[0]->tag, '4', 'new tag #4');
        is($tasks[0]->status, 'open', 'open task');
        is($tasks[0]->name, 'Create a new task', 'task name new');
    }
}

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

        is($task_objs[1]->tag, 'testing', 'new tag #testing');
        is($task_objs[1]->status, 'nix', 'nixed task');
        is($task_objs[1]->name, 'Create a nixed task', 'task name nixed');

        is($task_objs[2]->tag, '8', 'new tag #8');
        is($task_objs[2]->status, 'open', 'open task');
        is($task_objs[2]->name, 'Create a task without a specified status', 
            'task name unspecified');
    }
}

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
            qr/\Q$comment\E\s*#9\s*#A\s*#C\s*#D\s*#E\s*#F\s*/, 
            'comment is now missing the tasks');

        my @task_objs = $parser->created_tasks;
        my @all_tasks = $parser->tasks;
        is(scalar @task_objs, scalar @tasks, 'found three tasks created');
        is(scalar @task_objs, scalar @all_tasks, 'found three tasks');

        is($task_objs[0]->tag, '9', 'new tag #9');
        is($task_objs[0]->status, 'open', 'open task');
        is($task_objs[0]->name, 'Task 1', 'comment Task 1');
        ok($task_objs[0]->parent->is_none_project, 'Task 1 parent is none');
        ok($task_objs[0]->project->is_none_project, 'Task 1 project is none');

        is($task_objs[1]->tag, 'A', 'new tag #A');
        is($task_objs[1]->status, 'open', 'open task');
        is($task_objs[1]->name, 'Task 2', 'comment Task 2');
        ok($task_objs[1]->parent->is_none_project, 'Task 2 parent is none');
        ok($task_objs[1]->project->is_none_project, 'Task 2 project is none');

        is($task_objs[2]->tag, 'C', 'new tag #C');
        is($task_objs[2]->status, 'open', 'open task');
        is($task_objs[2]->name, 'Task 2A', 'comment Task 2A');
        is($task_objs[2]->parent->id, $task_objs[1]->id, 
            'Task 2A parent is Task 2');
        ok($task_objs[2]->project->is_none_project, 'Task 2A project is none');

        is($task_objs[3]->tag, 'D', 'new tag #D');
        is($task_objs[3]->status, 'open', 'open task');
        is($task_objs[3]->name, 'Task 2Ai', 'comment Task 2Ai');
        is($task_objs[3]->parent->id, $task_objs[2]->id, 
            'Task 2Ai parent is Task 2A');
        ok($task_objs[3]->project->is_none_project, 
            'Task 2Ai project is none');

        is($task_objs[4]->tag, 'E', 'new tag #E');
        is($task_objs[4]->status, 'open', 'open task');
        is($task_objs[4]->name, 'Task 2B', 'comment Task 2B');
        is($task_objs[4]->parent->id, $task_objs[1]->id, 
            'Task 2B parent is Task 2');
        ok($task_objs[4]->project->is_none_project, 'Task 2B project is none');

        is($task_objs[5]->tag, 'F', 'new tag #F');
        is($task_objs[5]->status, 'open', 'open task');
        is($task_objs[5]->name, 'Task 2C', 'comment Task 2C');
        is($task_objs[5]->parent->id, $task_objs[1]->id, 
            'Task 2C parent is Task 2');
        ok($task_objs[5]->project->is_none_project, 'Task 2C project is none');
    }
}

# Add a comment and update some tasks
{
    my $comment = qq/This is a test.\n\n/;
    my @tasks   = (
        qq/[ ] #testing/,
        qq/[x] #testing/,
        qq/[!] #testing/,
        qq/[-] #testing: New task text/,
        qq/[-] #testing: #testing2:/,
        qq/[-] #testing: #testing2: New task text/,
        qq/[-] +#testing: New task with same nick/,
    );
    my $joined_tasks = join "\n", @tasks;

    my $parser = Qublog::Util::CommentParser->new( 
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
            qr/\Q$comment\E
                \s* #testing
                \s* #testing
                \s* #testing
                \s* #testing
                \s* #testing2
                \s* #testing
                \s* #testing \s* /x, 'comment is now missing the tasks');

        my @all_tasks    = $parser->tasks;
        my @create_tasks = $parser->created_tasks;
        my @update_tasks = $parser->updated_tasks;
        is(scalar @all_tasks, scalar @tasks, 'found seven tasks');
        is(scalar @create_tasks, 1, 'found two creates');
        is(scalar @update_tasks, 6, 'found five updates');

        is($update_tasks[0]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[0]->status, 'open', 'open task');

        is($update_tasks[1]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[1]->status, 'done', 'done task');

        is($update_tasks[2]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[2]->status, 'nix', 'nixed task');

        is($update_tasks[3]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[3]->status, 'nix', 'nixed task');
        is($update_tasks[3]->name, 'New task text', 'comment New task text');

        is($update_tasks[4]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[4]->status, 'nix', 'nixed task');
        is($update_tasks[4]->name, 'New task text', 'comment New task text');

        is($update_tasks[5]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[5]->status, 'nix', 'nixed task');
        is($update_tasks[5]->name, 'New task text', 
            'comment New task text');

        is($create_tasks[0]->tag, 'testing', 'new tag #testing');
        is($create_tasks[0]->status, 'open', 'open task');
        is($create_tasks[0]->name, 'New task with same nick', 
            'comment New task with same nick');
    }
}

