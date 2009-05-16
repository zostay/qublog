#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

Test the various features of the create journal thingy action.

=cut

use lib 't/lib';
use Jifty::Test tests => 69;
use Qublog::Test;
setup_test_user;

# Make sure we can load the action
use_ok('Qublog::Action::CreateJournalThingy');

sub new_cjt {
    my %arguments = @_;
    return Jifty->web->new_action(
        class     => 'CreateJournalThingy',
        arguments => \%arguments,
    );
}

sub verify_task {
    my ($tasks, $nickname, $name) = @_;

    my $task = $tasks->next;
    ok($task, 'got the next task');
    SKIP: {
        skip "expected task #$nickname not found", 2 unless $task;

        is($task->tag, $nickname, "task has nickname #$nickname");
        is($task->name, $name, "task has name $name");
    }
}

sub verify_comment {
    my ($comments, $name, @items) = @_;

    my $comment = $comments->next;
    ok($comment, 'got the next comment');
    SKIP: {
        skip "expected comment $name not found", @items + 1 unless $comment;

        is($comment->name, $name, "comment has name $name");
        for my $item (@items) {
            if ($item->isa('Qublog::Model::Task')) {
                my $found;
                my $task_logs = $comment->task_logs;
                TASK_LOG: while (my $task_log = $task_logs->next) {
                    if ($task_log->comment->id == $comment->id) {
                        $found++;
                        last TASK_LOG;
                    }
                }

                ok($found, "comment $name belongs to task ".$item->tag);
            }
            elsif ($item->isa('Qublog::Model::JournalTimer')) {
                is($comment->journal_timer->id, $item->id,
                    "comment $name belongs to timer ".$item->id);
            }
            else {
                die "Bad test. Fix it.";
            }
        }
    }
}

# Create a new task
{
    my $cjt = new_cjt( task_entry => '#blah', comment => 'This is a task' );
    is($cjt->thingy_button, 'Taskinate', 'creating a task');
    $cjt->run;

    is($cjt->result->success, 1, 'we did something successfully');
    is($cjt->result->message, 'Created a new task #blah.', 'created #blah');
}

# We should now have some tasks
{
    my $tasks = Qublog::Model::TaskCollection->new();
    $tasks->unlimit;

    is($tasks->count, 2, 'we now have two tasks');
    verify_task($tasks, 3, 'none');
    verify_task($tasks, 'blah', 'This is a task');

    my $comments = Qublog::Model::CommentCollection->new();
    $comments->unlimit;

    is($comments->count, 0, 'we have no comments yet');
}

# Comment on a task
{
    my $cjt = new_cjt( task_entry => '#blah', comment => 'This is a comment on a task' );
    is($cjt->thingy_button, 'Comment', 'commenting on a task');
    $cjt->run;

    is($cjt->result->success, 1, 'we did something successfully');
    is($cjt->result->message, 'Added a comment to task #blah.', 'commented on #blah');
}

# We should now have a comment on a task
{
    my $tasks = Qublog::Model::TaskCollection->new();
    $tasks->unlimit;

    is($tasks->count, 2, 'we still have two tasks');
    my $task = $tasks->items_array_ref->[1];

    my $comments = Qublog::Model::CommentCollection->new();
    $comments->unlimit;

    is($comments->count, 1, 'we have one comment');
    verify_comment($comments, 'This is a comment on a task', $task);
}

# Create a new entry, timer, and comment
{
    my $cjt = new_cjt( task_entry => '#blah: foo', comment => 'This is the first comment on a timer' );
    is($cjt->thingy_button, 'Start', 'starting a new timer');
    $cjt->run;

    is($cjt->result->success, 1, 'we did something successfully');
    is($cjt->result->message, 'Started #blah: foo and added your comment.', 'started #blah: foo');
}

# We should now have a comment on a timer
{
    my $journals = Qublog::Model::JournalEntryCollection->new();
    $journals->unlimit;

    is($journals->count, 1, 'we now have one entry');
    my $journal = $journals->first;
    is($journal->name, '#blah: foo', 'journal is #blah: foo');

    my $timers = Qublog::Model::JournalTimerCollection->new();
    $timers->unlimit;

    is($timers->count, 1, 'we now have one timer');
    my $timer = $timers->first;
    is($timer->journal_entry->id, $journal->id, 'timer belongs to the expected entry');

    my $comments = Qublog::Model::CommentCollection->new();
    $comments->unlimit;

    is($comments->count, 2, 'we now have 2 comments');
    verify_comment($comments, 'This is a comment on a task');
    verify_comment($comments, 'This is the first comment on a timer', $timer);
}

# Add another comment here
{
    my $cjt = new_cjt( task_entry => '#blah: foo', comment => 'This is another comment on a timer' );
    is($cjt->thingy_button, 'Post', 'posting to a timer');
    $cjt->run;

    is($cjt->result->success, 1, 'we did something successfully');
    is($cjt->result->message, 'Added a new comment to the current timer.', 'commented on #blah: foo');
}

# We should have two comments on the same timer
{
    my $journals = Qublog::Model::JournalEntryCollection->new();
    $journals->unlimit;

    is($journals->count, 1, 'we now have one entry');
    my $journal = $journals->first;
    is($journal->name, '#blah: foo', 'journal is #blah: foo');

    my $timers = Qublog::Model::JournalTimerCollection->new();
    $timers->unlimit;

    is($timers->count, 1, 'we now have one timer');
    my $timer = $timers->first;
    is($timer->journal_entry->id, $journal->id, 'timer belongs to the expected entry');

    my $comments = Qublog::Model::CommentCollection->new();
    $comments->unlimit;

    is($comments->count, 3, 'we now have 3 comments');
    verify_comment($comments, 'This is a comment on a task');
    verify_comment($comments, 'This is the first comment on a timer', $timer);
    verify_comment($comments, 'This is another comment on a timer', $timer);

    # Stop the timer so the next will be a restart
    $journal->stop_timer;
}

# Add another comment as a restart
{
    my $cjt = new_cjt( task_entry => '#blah: foo', comment => 'This is the first comment on a new timer for an existing entry'  );
    is($cjt->thingy_button, 'Restart', 'restarting a timer');
    $cjt->run;

    is($cjt->result->success, 1, 'we did something successfully');
    is($cjt->result->message, 'Restarted #blah: foo and added your comment.', 'restarted #blah: foo');
}

# We should have three comments on the same entry
{
    my $journals = Qublog::Model::JournalEntryCollection->new();
    $journals->unlimit;

    is($journals->count, 1, 'we now have one entry');
    my $journal = $journals->first;
    is($journal->name, '#blah: foo', 'journal is #blah: foo');

    my $timers = Qublog::Model::JournalTimerCollection->new();
    $timers->unlimit;

    is($timers->count, 2, 'we now have two timers');
    my $timer1 = $timers->next;
    is($timer1->journal_entry->id, $journal->id, 'timer belongs to the expected entry');
    my $timer2 = $timers->next;
    is($timer2->journal_entry->id, $journal->id, 'timer belongs to the expected entry');

    my $comments = Qublog::Model::CommentCollection->new();
    $comments->unlimit;

    is($comments->count, 4, 'we now have 4 comments');
    verify_comment($comments, 'This is a comment on a task');
    verify_comment($comments, 'This is the first comment on a timer', $timer1);
    verify_comment($comments, 'This is another comment on a timer', $timer1);
    verify_comment($comments, 'This is the first comment on a new timer for an existing entry', $timer2);

    # Stop the timer so the next will be a restart
    $journal->stop_timer;
}

