#!/usr/bin/perl
use strict;
use warnings;

package Qublog::Test::CommentParser::Single;
use base qw( Qublog::Test::CommentParser );

use Test::More;

# Add a simple comment and a single task
sub simple_comment_and_single_task {
    my $self = shift;
    
    my $project = $self->{project};

    my $comment = qq/This is a test.\n\n/;
    my $task    = qq/[ ] Create a new task/;

    my $parser = Qublog::Util::CommentParser->new( 
        project => $project,
        comment => $self->{comment},
        text    => $comment.$task 
    );

    {
        is($parser->text, $comment.$task, 
            'comment starts matching original');

        $self->number_of_task_logs_is( all => 0 );
    }

    $parser->execute;

    {
        my @tasks = $self->number_of_task_logs_is( created => 1 );
        $self->number_of_task_logs_is( all => 1 );

        $self->check_comment_text(
            $parser->text, [
                "\Q$comment\E\\s* \\*",
            ], \@tasks);


        is($tasks[0]->task->status, 'open', 'open task');
        is($tasks[0]->task->name, 'Create a new task', 'task name new');
        is($tasks[0]->task->project->id, $project->id, 'project set');
        is($tasks[0]->task->parent->id, $project->id, 'parent set');
    }
}

1;
