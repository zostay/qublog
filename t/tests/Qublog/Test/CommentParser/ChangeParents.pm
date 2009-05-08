#!/usr/bin/perl
use strict;
use warnings;

package Qublog::Test::CommentParser::ChangeParents;
use base qw( Qublog::Test::CommentParser );

use Test::More;

sub simple_parent_set_create : Test(14) {
    my $self = shift;

    my $comment = qq/This is a test.\n\n/;
    my $task    = qq/[ ] #foo: Create a new task\n/;
       $task   .= qq/[ ] #bar: Another new task/;

    my $project     = $self->{project};
    my $comment_obj = $self->{comment};

    my $parser = Qublog::Util::CommentParser->new( 
        project => $project,
        text    => $comment.$task,
        comment => $comment_obj,
    );

    {
        is($parser->text, $comment.$task, 
            'comment starts matching original');

        $self->number_of_task_logs_is( all => 0 );
    }

    $parser->execute;

    {
        my @tasks = $self->number_of_task_logs_is( create => 2 );
        $self->number_of_task_logs_is( all => 2 );

        is($tasks[0]->task->tag, 'foo', 'new tag #foo');
        is($tasks[0]->task->status, 'open', 'open task');
        is($tasks[0]->task->name, 'Create a new task', 'task name new');
        is($tasks[0]->task->project->id, $project->id, 'project set');
        is($tasks[0]->task->parent->id, $project->id, 'parent set');

        is($tasks[1]->task->tag, 'bar', 'new tag #bar');
        is($tasks[1]->task->status, 'open', 'open task');
        is($tasks[1]->task->name, 'Another new task', 'task name new');
        is($tasks[1]->task->project->id, $project->id, 'project set');
        is($tasks[1]->task->parent->id, $project->id, 'parent set');
    }
}

sub simple_parent_set_update : Test(11) {
    my $self = shift;

    my $project     = $self->{project};
    my $comment_obj = $self->{comment};

    my $rearrange_tasks = qq/[-] #foo\n-[-] #bar/;
    my $parser = Qublog::Util::CommentParser->new(
        project => $project,
        text    => $rearrange_tasks,
        comment => $comment_obj,
    );

    $parser->execute;

    my @tasks = $self->number_of_task_logs_is( update => 2 );

    is($tasks[0]->task->tag, 'foo', 'updated tag #foo');
    is($tasks[0]->task->status, 'open', 'open task');
    is($tasks[0]->task->name, 'Create a new task', 'task is same');
    is($tasks[0]->task->project->id, $project->id, 'project set');
    is($tasks[0]->task->parent->id, $project->id, 'parent set');

    is($tasks[1]->task->tag, 'bar', 'updated tag #bar');
    is($tasks[1]->task->status, 'open', 'open task');
    is($tasks[1]->task->name, 'Another new task', 'task is isame');
    is($tasks[1]->task->project->id, $project->id, 'project same');
    is($tasks[1]->task->parent->id, $tasks[0]->task->id, 'parent changed');
}

1;
