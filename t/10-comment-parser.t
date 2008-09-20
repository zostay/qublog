#!/usr/bin/perl
use strict;
use warnings;

use Jifty::Everything;
Jifty->new;

use Test::MockModule;
use Test::More tests => 73;
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
        like($parser->comment, qr/\Q$comment\E\s*#2\s*/, 
            'comment is now missing the task');

        my @tasks = $parser->created_tasks;
        my @all_tasks = $parser->tasks;
        is(scalar @tasks, 1, 'found one task created');
        is(scalar @all_tasks, 1, 'found one task');

        is($tasks[0]->nickname, '2', 'new nickname #2');
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
        like($parser->comment, qr/\Q$comment\E\s*#3\s*#testing\s*#5\s*/, 
            'comment is now missing the tasks');

        my @task_objs = $parser->created_tasks;
        my @all_tasks = $parser->tasks;
        is(scalar @task_objs, scalar @tasks, 'found three tasks created');
        is(scalar @task_objs, scalar @all_tasks, 'found three tasks');

        is($task_objs[0]->nickname, '3', 'new nickname #3');
        is($task_objs[0]->status, 'done', 'done task');
        is($task_objs[0]->name, 'Create a done task', 'task name done');

        is($task_objs[1]->nickname, 'testing', 'new nickname #testing');
        is($task_objs[1]->status, 'nix', 'nixed task');
        is($task_objs[1]->name, 'Create a nixed task', 'task name nixed');

        is($task_objs[2]->nickname, '5', 'new nickname #5');
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
            qr/\Q$comment\E\s*#6\s*#7\s*#8\s*#9\s*#A\s*#B\s*/, 
            'comment is now missing the tasks');

        my @task_objs = $parser->created_tasks;
        my @all_tasks = $parser->tasks;
        is(scalar @task_objs, scalar @tasks, 'found three tasks created');
        is(scalar @task_objs, scalar @all_tasks, 'found three tasks');

        is($task_objs[0]->nickname, '6', 'new nickname #6');
        is($task_objs[0]->status, 'open', 'open task');
        is($task_objs[0]->name, 'Task 1', 'comment Task 1');
        ok($task_objs[0]->parent->is_none_project, 'Task 1 parent is none');
        ok($task_objs[0]->project->is_none_project, 'Task 1 project is none');

        is($task_objs[1]->nickname, '7', 'new nickname #7');
        is($task_objs[1]->status, 'open', 'open task');
        is($task_objs[1]->name, 'Task 2', 'comment Task 2');
        ok($task_objs[1]->parent->is_none_project, 'Task 2 parent is none');
        ok($task_objs[1]->project->is_none_project, 'Task 2 project is none');

        is($task_objs[2]->nickname, '8', 'new nickname #8');
        is($task_objs[2]->status, 'open', 'open task');
        is($task_objs[2]->name, 'Task 2A', 'comment Task 2A');
        is($task_objs[2]->parent->id, $task_objs[1]->id, 
            'Task 2A parent is Task 2');
        ok($task_objs[2]->project->is_none_project, 'Task 2A project is none');

        is($task_objs[3]->nickname, '9', 'new nickname #9');
        is($task_objs[3]->status, 'open', 'open task');
        is($task_objs[3]->name, 'Task 2Ai', 'comment Task 2Ai');
        is($task_objs[3]->parent->id, $task_objs[2]->id, 
            'Task 2Ai parent is Task 2A');
        ok($task_objs[3]->project->is_none_project, 
            'Task 2Ai project is none');

        is($task_objs[4]->nickname, 'A', 'new nickname #A');
        is($task_objs[4]->status, 'open', 'open task');
        is($task_objs[4]->name, 'Task 2B', 'comment Task 2B');
        is($task_objs[4]->parent->id, $task_objs[1]->id, 
            'Task 2B parent is Task 2');
        ok($task_objs[4]->project->is_none_project, 'Task 2B project is none');

        is($task_objs[5]->nickname, 'B', 'new nickname #B');
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
        is($parser->comment, $comment, 'comment is now missing the tasks');

        my @task_objs = $parser->tasks;
        is(scalar @task_objs, scalar @tasks, 'found seven tasks');

        ok($task_objs[0]->is_update, "task 0 is an update");
        is($task_objs[0]->record->id, 1, 'task 0 has a task to update');
        is_deeply($task_objs[0]->arguments, {
            status => 'open',
        }, 'task 0 has status');

        ok($task_objs[1]->is_update, "task 1 is an update");
        is($task_objs[1]->record->id, 1, 'task 1 has a task to update');
        is_deeply($task_objs[1]->arguments, {
            status => 'done',
        }, 'task 1 has status');

        ok($task_objs[2]->is_update, "task 2 is an update");
        is($task_objs[2]->record->id, 1, 'task 2 has a task to update');
        is_deeply($task_objs[2]->arguments, {
            status => 'nix',
        }, 'task 2 has status');

        ok($task_objs[3]->is_update, "task 3 is an update");
        is($task_objs[3]->record->id, 1, 'task 3 has a task to update');
        is_deeply($task_objs[3]->arguments, {
            name => 'New task text',
        }, 'task 3 has name argument');

        ok($task_objs[4]->is_update, "task 4 is an update");
        is($task_objs[4]->record->id, 1, 'task 4 has a task to update');
        is_deeply($task_objs[4]->arguments, {
            alternate_nickname => 'testing2',
        }, 'task 4 has alternate_nickname argument');

        ok($task_objs[5]->is_update, "task 5 is an update");
        is($task_objs[5]->record->id, 1, 'task 5 has a task to update');
        is_deeply($task_objs[5]->arguments, {
            name               => 'New task text',
            alternate_nickname => 'testing2',
        }, 'task 5 has name and alternate_nickname argument');

        ok(!$task_objs[6]->is_update, "task 6 is not an update");
        is_deeply($task_objs[6]->arguments, {
            name               => 'New task with same nick',
            alternate_nickname => 'testing',
        }, 'task 5 has name and alternate_nickname argument');
    }
}

