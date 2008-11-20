#!/usr/bin/perl
use strict;
use warnings;

require 't/30-CommentParser.pl';
use Test::More tests => 30;

use vars qw( $project );

# Add a comment and update some tasks
{
    my $comment = qq/This is a test.\n\n/;
    my @tasks   = (
        qq/[ ] #testing: A fancy pantsy new task/,
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
        is(scalar @create_tasks, 2, 'found two creates');
        is(scalar @update_tasks, 5, 'found five updates');

        is($update_tasks[0]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[0]->status, 'done', 'done task');

        is($update_tasks[1]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[1]->status, 'nix', 'nixed task');

        is($update_tasks[2]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[2]->status, 'nix', 'nixed task');
        is($update_tasks[2]->name, 'New task text', 'comment New task text');

        is($update_tasks[3]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[3]->status, 'nix', 'nixed task');
        is($update_tasks[3]->name, 'New task text', 'comment New task text');

        is($update_tasks[4]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[4]->status, 'nix', 'nixed task');
        is($update_tasks[4]->name, 'New task text', 
            'comment New task text');

        is($update_tasks[0]->tag, 'testing2', 'tag #testing2');
        is($update_tasks[0]->status, 'done', 'done task');
        is($create_tasks[0]->name, 'A fancy pantsy new task', 'new task name');

        is($create_tasks[1]->tag, 'testing', 'new tag #testing');
        is($create_tasks[1]->status, 'open', 'open task');
        is($create_tasks[1]->name, 'New task with same nick', 
            'comment New task with same nick');
    }
}
