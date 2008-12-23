#!/usr/bin/perl
use strict;
use warnings;

package Qublog::Test::CommentParser::Multiple;
use base qw( Qublog::Test::CommentParser );

use Test::More;

sub three_more_complex_tests : Test(17) {
    my $self = shift;

    my $project = $self->{project};

    my $comment = qq/This is a test.\n\n/;
    my @tasks   = (
        qq/[x] Create a done task/,
        qq/ [!]   #testing: Create a nixed task/,
        qq/[-] Create a task without a specified status /,
    );
    my $joined_tasks = join "\n", @tasks;

    my $parser = Qublog::Util::CommentParser->new( 
        project => $project,
        comment => $self->{comment},
        text    => $comment.$joined_tasks,
    );

    {
        is($parser->text, $comment.$joined_tasks, 
            'comment starts matching original');

        $self->number_of_task_logs_is( all => 0 );
    }

    $parser->execute;

    {
        my @task_objs = $self->number_of_task_logs_is( create => 3 );
        my @all_tasks = $self->number_of_task_logs_is( all => 3 );

        $self->check_comment_text(
            $parser->text, [
                "\Q$comment\E\\s* \\*\\s*",
                "\\s* \\*\\s*",
                "\\s* \\*\\s*",
            ], \@task_objs);

        is($task_objs[0]->task->status, 'done', 'done task');
        is($task_objs[0]->task->name, 'Create a done task', 'task name done');
        is($task_objs[0]->task->project->id, $project->id, 'project set');
        is($task_objs[0]->task->parent->id, $project->id, 'parent set');

        is($task_objs[1]->task->status, 'nix', 'nixed task');
        is($task_objs[1]->task->name, 'Create a nixed task', 'task name nixed');
        is($task_objs[1]->task->project->id, $project->id, 'project set');
        is($task_objs[1]->task->parent->id, $project->id, 'parent set');

        is($task_objs[2]->task->status, 'open', 'open task');
        is($task_objs[2]->task->name, 'Create a task without a specified status', 
            'task name unspecified');
        is($task_objs[2]->task->project->id, $project->id, 'project set');
        is($task_objs[2]->task->parent->id, $project->id, 'parent set');
    }
}

1;
