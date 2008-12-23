#!/usr/bin/perl
use strict;
use warnings;

package Qublog::Test::CommentParser::Hierarchy;
use base qw( Qublog::Test::CommentParser );

use Test::More;

sub comment_and_six_nested_tasks : Test(29) {
    my $self = shift;

    my $project = $self->{project};

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
        comment => $self->{comment},
        text    => $comment.$joined_tasks
    );

    {
        is($parser->text, $comment.$joined_tasks, 
            'comment starts matching original');

        $self->number_of_task_logs_is( all => 0 );
    }

    $parser->execute;

    {
        my @task_objs = $self->number_of_task_logs_is( create => scalar @tasks);
        $self->number_of_task_logs_is( all => scalar @tasks );

        my @bits = (
            "\Q$comment\E\\s* \\*\\s*",
            "\\s* \\*\\s*",
            "\\s*   \\*\\s*",
            "\\s*     \\*\\s*",
            "\\s*   \\*\\s*",
            "\\s*   \\*\\s*",
        );

        my $expected_text = '';
        for my $i (0 .. $#bits) {
            $expected_text .= $bits[$i] 
                           .  '#' . $task_objs[$i]->task->tag
                           .  '\*' . $task_objs[$i]->id;
        }

        like($parser->text, qr/$expected_text/, 'comment has been rewritten');

        is($task_objs[0]->task->status, 'open', 'open task');
        is($task_objs[0]->task->name, 'Task 1', 'comment Task 1');
        is($task_objs[0]->task->parent->id, $project->id, 'Task 1 parent is set');
        is($task_objs[0]->task->project->id, $project->id, 'Task 1 project is set');

        is($task_objs[1]->task->status, 'open', 'open task');
        is($task_objs[1]->task->name, 'Task 2', 'comment Task 2');
        is($task_objs[1]->task->parent->id, $project->id, 'Task 2 parent is set');
        is($task_objs[1]->task->project->id, $project->id, 'Task 2 project is set');

        is($task_objs[2]->task->status, 'open', 'open task');
        is($task_objs[2]->task->name, 'Task 2A', 'comment Task 2A');
        is($task_objs[2]->task->parent->id, $task_objs[1]->task->id, 
            'Task 2A parent is Task 2');
        is($task_objs[2]->task->project->id, $project->id, 'Task 2A project is set');

        is($task_objs[3]->task->status, 'open', 'open task');
        is($task_objs[3]->task->name, 'Task 2Ai', 'comment Task 2Ai');
        is($task_objs[3]->task->parent->id, $task_objs[2]->task->id, 
            'Task 2Ai parent is Task 2A');
        is($task_objs[3]->task->project->id, $project->id, 
            'Task 2Ai project is set');

        is($task_objs[4]->task->status, 'open', 'open task');
        is($task_objs[4]->task->name, 'Task 2B', 'comment Task 2B');
        is($task_objs[4]->task->parent->id, $task_objs[1]->task->id, 
            'Task 2B parent is Task 2');
        is($task_objs[4]->task->project->id, $project->id, 'Task 2B project is set');

        is($task_objs[5]->task->status, 'open', 'open task');
        is($task_objs[5]->task->name, 'Task 2C', 'comment Task 2C');
        is($task_objs[5]->task->parent->id, $task_objs[1]->task->id, 
            'Task 2C parent is Task 2');
        is($task_objs[5]->task->project->id, $project->id, 'Task 2C project is set');
    }
}

1;
