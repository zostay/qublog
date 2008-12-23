#!/usr/bin/perl
use strict;
use warnings;

package Qublog::Test::CommentParser::Updates;
use base qw( Qublog::Test::CommentParser );

use Test::More;

# Add a comment and update some tasks
sub update_some_tasks : Tests(25) {
    my $self = shift;

    my $project = $self->{project};

    my $comment = qq/This is a test.\n\n/;
    my @tasks   = (
        qq/[ ] #update: A fancy pantsy new task/,
        qq/[x] #update/,
        qq/[!] #update/,
        qq/[-] #update: New task text/,
        qq/[-] #update: #update2:/,
        qq/[-] #update: #update2: New task text/,
        qq/[-] +#update: New task with same nick/,
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

        my @all_tasks    = $self->number_of_task_logs_is( all => 7 );
        my @create_tasks = $self->number_of_task_logs_is( create => 2 );
        my @update_tasks = $self->number_of_task_logs_is( update => 5 );

        $self->check_comment_text(
            $parser->text, [
                [ "\Q$comment\E\\s* \\*\\s*#update" ],
                [ "\\s* \\*\\s*#update" ],
                [ "\\s* \\*\\s*#update" ],
                [ "\\s* \\*\\s*#update" ],
                "\\s* \\*\\s*",
                "\\s* \\*\\s*",
                "\\s* \\*\\s*",
            ], \@all_tasks);

        is($update_tasks[0]->task->tag, 'update2', 'tag #update2');
        is($update_tasks[0]->task->status, 'nix', 'nixed task');

        is($update_tasks[1]->task->tag, 'update2', 'tag #update2');
        is($update_tasks[1]->task->status, 'nix', 'nixed task');

        is($update_tasks[2]->task->tag, 'update2', 'tag #update2');
        is($update_tasks[2]->task->status, 'nix', 'nixed task');
        is($update_tasks[2]->task->name, 'New task text', 'comment New task text');

        is($update_tasks[3]->task->tag, 'update2', 'tag #update2');
        is($update_tasks[3]->task->status, 'nix', 'nixed task');
        is($update_tasks[3]->task->name, 'New task text', 'comment New task text');

        is($update_tasks[4]->task->tag, 'update2', 'tag #update2');
        is($update_tasks[4]->task->status, 'nix', 'nixed task');
        is($update_tasks[4]->task->name, 'New task text', 
            'comment New task text');

        is($create_tasks[0]->task->tag, 'update2', 'tag #update2');
        is($create_tasks[0]->task->status, 'nix', 'open task');
        is($create_tasks[0]->task->name, 'New task text', 'new task name');

        is($create_tasks[1]->task->tag, 'update', 'new tag #update');
        is($create_tasks[1]->task->status, 'open', 'open task');
        is($create_tasks[1]->task->name, 'New task with same nick', 
            'comment New task with same nick');
    }
}

1;
