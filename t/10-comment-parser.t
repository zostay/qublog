#!/usr/bin/perl
use strict;
use warnings;

use Jifty::Everything;
Jifty->new;

use Test::MockModule;
use Test::More tests => 67;

use_ok('Qublog::Util::CommentParser');

# Simple test of the class using an empty comment
{
    my $parser = Qublog::Util::CommentParser->new( comment => '' );

    can_ok($parser, 'comment');
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

# Mocking Qublog::Module::Task
my $module = Test::MockModule->new('Qublog::Model::Task');
$module->mock( 'id'  => undef );

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
        is($parser->comment, $comment, 'comment is now missing the task');

        my @tasks = $parser->tasks;
        is(scalar @tasks, 1, 'found one task');

        can_ok($tasks[0], 'record');
        can_ok($tasks[0], 'is_update');
        can_ok($tasks[0], 'arguments');

        ok(!$tasks[0]->is_update, 'task 0 is not an update');
        is_deeply($tasks[0]->arguments, {
            status => 'open',
            name   => 'Create a new task',
        }, 'task 0 has status and name arguments');
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
        is($parser->comment, $comment, 'comment is now missing the tasks');

        my @task_objs = $parser->tasks;
        is(scalar @task_objs, scalar @tasks, 'found three tasks');

        ok(!$task_objs[0]->is_update, "task 0 is not an update");
        is_deeply($task_objs[0]->arguments, {
            status => 'done',
            name   => 'Create a done task',
        }, 'task 0 has status and name arguments');

        ok(!$task_objs[1]->is_update, "task 1 is not an update");
        is_deeply($task_objs[1]->arguments, {
            status             => 'nix',
            name               => 'Create a nixed task',
            alternate_nickname => 'testing',
        }, 'task 1 has status, nickname, and name arguments');

        ok(!$task_objs[2]->is_update, "task 2 is not an update");
        is_deeply($task_objs[2]->arguments, {
            name   => 'Create a task without a specified status',
        }, 'task 1 has name argument');
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
        is($parser->comment, $comment, 'comment is now missing the tasks');

        my @task_objs = $parser->tasks;
        is(scalar @task_objs, scalar @tasks, 'found six tasks');

        ok(!$task_objs[0]->is_update, "task 0 is not an update");
        is_deeply($task_objs[0]->arguments, {
            status => 'open',
            name   => 'Task 1',
        }, 'task 0 has status and name arguments');

        ok(!$task_objs[1]->is_update, "task 1 is not an update");
        is_deeply($task_objs[1]->arguments, {
            status             => 'open',
            name               => 'Task 2',
        }, 'task 1 has status and name arguments');

        ok(!$task_objs[2]->is_update, "task 2 is not an update");
        is_deeply($task_objs[2]->arguments, {
            parent => $task_objs[1],
            status => 'open',
            name   => 'Task 2A',
        }, 'task 2 has name, status, and parent="task 1" arguments');

        ok(!$task_objs[3]->is_update, "task 3 is not an update");
        is_deeply($task_objs[3]->arguments, {
            parent => $task_objs[2],
            status => 'open',
            name   => 'Task 2Ai',
        }, 'task 3 has name, status, and parent="task 2" arguments');

        ok(!$task_objs[4]->is_update, "task 4 is not an update");
        is_deeply($task_objs[4]->arguments, {
            parent => $task_objs[1],
            status => 'open',
            name   => 'Task 2B',
        }, 'task 4 has name, status, and parent="task 1" arguments');

        ok(!$task_objs[5]->is_update, "task 5 is not an update");
        is_deeply($task_objs[5]->arguments, {
            parent => $task_objs[1],
            status => 'open',
            name   => 'Task 2C',
        }, 'task 5 has name, status, and parent="task 1" arguments');
    }
}

# Mocking Qublog::Module::Task for update
# Essentially, this pretends we find something if load_by_nickname is even
# called. Otherwise, we found nothing. This allows us to have the test set
# below work when we use "+" to force a new item even though a nickname is
# given.
$module->mock( 'id'               => sub { shift->{__loaded_id} } );
$module->mock( 'load_by_nickname' => sub { shift->{__loaded_id} = 1 } );

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

