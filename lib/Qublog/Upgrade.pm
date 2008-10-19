use strict;
use warnings;

package Qublog::Upgrade;
use base qw/ Jifty::Upgrade /;
use Jifty::Upgrade qw/ since /;

=head1 NAME

Qublog::Upgrade - upgrade script for the Qublog application

=head1 UPGRADES

=head2 0.3.0

Nicknames have been expanded into their own table. Existing nicknames will be automatically dropped into the new nickname table, but using the old base-36 numbering scheme.

=cut

since '0.3.0' => sub {
    my $tasks = Qublog::Model::TaskCollection->new;
    $tasks->unlimit;

    my $base36 = Math::BaseCalc->new( digits => [ '0' .. '9', 'A' .. 'Z' ] );
    my $nickname = Qublog::Model::Nickname->new;
    while (my $task = $tasks->next) {
        my $autonick = $base36->to_base($task->id);

        $nickname->create(
            nickname  => $autonick,
            kind      => 'Task',
            object_id => $task->id,
            sticky    => 1,
        );

        if ($task->alternate_nickname) {
            warn "Adding custom nickname ",$task->alternate_nickname," to ",
                $autonick,"\n";
            $nickname->create(
                nickname  => $task->alternate_nickname,
                kind      => 'Task',
                object_id => $task->id,
                sticky    => 0,
            );
        }
    }
};

=head2 0.2.4

Collapsing C<Qublog::Model::CommentTaskLink> into L<Qublog::Model::TaskLog> since having the extra table is just confusing.

In this revision, the "link" setting for L<Qublog::Model::TaskLog/log_type> is going away, so we rename all those to "note".

=cut

since '0.2.4' => sub {
    my $comment_task_links = Qublog::Model::CommentTaskLinkCollection->new;
    $comment_task_links->unlimit;

    while (my $comment_task_link = $comment_task_links->next) {
        my $task_log = $comment_task_link->task_log;

        if ($task_log->id) {
            $task_log->set_comment( $comment_task_link->journal_comment );
        }

        else {
            $task_log->create(
                task       => $comment_task_link->task,
                log_type   => 'note',
                created_on => $comment_task_link->journal_comment->created_on,
                comment    => $comment_task_link->journal_comment,
            );
        }
    }

    my $task_logs = Qublog::Model::TaskLogCollection->new;
    $task_logs->limit( column => 'log_type', value => 'link' );

    while (my $task_log = $task_logs->next) {
        $task_log->set_log_type( 'note' );
    }
};

=head2 0.2.2

Renaming C<Qublog::Model::JournalComment> to L<Qublog::Model::Comment>.

=cut

since '0.2.2' => sub {
    my $journal_comments = Qublog::Model::JournalCommentCollection->new;
    $journal_comments->unlimit;    

    my $comment = Qublog::Model::Comment->new;
    while (my $journal_comment = $journal_comments->next) {
        $comment->create( $journal_comment->as_hash );
    }
};

=head2 0.2.1

The C<journal_entry> field of L<Qublog::Model::Comment> has been replaced with a direct link to C<journal_timer>. All the old C<journal_entry> links need to be moved to the corresponding timer.

=cut

since '0.2.1' => sub {
    my $dbh = Jifty->handle->dbh;

    my $comments = Qublog::Model::CommentCollection->new;
    $comments->unlimit;

    my $timers = Qublog::Model::JournalTimerCollection->new;

    COMMENT:
    while (my $comment = $comments->next) {
        my $entry_id = $dbh->selectrow_array(
            "SELECT journal_entry FROM journal_comments WHERE id = ?", undef,
            $comment->id
        );

        $timers->unlimit;
        $timers->limit( column => 'journal_entry', value => $entry_id );
        $timers->order_by( { column => 'start_time' } );
        while (my $timer = $timers->next) {
            if ($timer->start_time <= $comment->created_on
                    and $timer->stop_time >= $comment->created_on) {

                $comment->set_journal_timer( $timer );
                next COMMENT;
            }
        }

        # Still here? Do it again, but just find the latest start_time before
        # this comment's create_on time
        my $remember_timer;
        while (my $timer = $timers->next) {
            if ($timer->start_time <= $comment->created_on) {
                $remember_timer = $timer;
            }
        }
        
        if ($remember_timer) {
            $comment->set_journal_timer( $remember_timer );
            next COMMENT;
        }

        # Still here!? Use the first one then
        $comment->set_journal_timer( $timers->first );
    }

    # Stupid
    warn "YOU MAY NEED TO CHECK YOUR DATABASE AND DROP THE journal_entry "
        ."COLUMN FROM THE\njournal_comments TABLE.\n";
};

=head2 0.2.0

Adds L<Qublog::Model::JournalDay> objects for all the existing L<Qublog::Model::JournalEntry> and L<Qublog::Model::Comment> objects.

=cut

since '0.2.0' => sub {
    my $day = Qublog::Model::JournalDay->new;

    my $entries = Qublog::Model::JournalEntryCollection->new;
    $entries->unlimit;

    while (my $entry = $entries->next) {
        $day->for_date( $entry->start_time );
        $entry->set_journal_day( $day );

        my $comments = $entry->comments;
        while (my $comment = $comments->next) {
            $comment->set_journal_day( $day );
        }
    }
};

=head2 0.1.4

=over

=item *

Created missing L<Qublog::Model::TaskLog> items for existing L<Qublog::Model::CommentTaskLink> objects.

=item *

Created additional L<Qublog::Model::TaskLog> objects for comment links.

=back

=cut

since '0.1.4' => sub {
    my $links = Qublog::Model::CommentTaskLinkCollection->new;
    $links->unlimit;

    while (my $link = $links->next) {
        my $comment = $link->journal_comment;
        my $task    = $link->task;

        my $name    = $comment->name;
        $comment->set_name( $name . "\n#" . $task->nickname );

        my $task_log = Qublog::Model::TaskLog->new;
        $task_log->create(
            task       => $task,
            created_on => $comment->created_on,
            log_type   => 'link',
        );

        $link->set_task_log($task_log);
    }

    my $comments = Qublog::Model::CommentCollection->new;
    $comments->unlimit;

    while (my $comment = $comments->next) {
        my @nicknames = $comment->name =~ /#(\w+)/g;

        my $task = Qublog::Model::Task->new;
        for my $nickname (@nicknames) {

            $task->load_by_nickname($nickname);
            if ($task->id) {
                my $task_log = Qublog::Model::TaskLog->new;
                $task_log->create(
                    task       => $task,
                    created_on => $comment->created_on,
                    log_type   => 'link',
                );

                my $link = Qublog::Model::CommentTaskLink->new;
                $link->create(
                    journal_comment => $comment,
                    task            => $task,
                    task_log        => $task_log,
                );
            }
        }
    }
};

=head2 0.1.2

Added the L<Qublog::Model::JournalTimer> objects for existing L<Qublog::Model::JournalEntry> objects.

=cut

since '0.1.2' => sub {
    my $entries = Qublog::Model::JournalEntryCollection->new;
    $entries->unlimit;

    my $timer = Qublog::Model::JournalTimer->new;
    while (my $entry = $entries->next) {
        $timer->create(
            journal_entry => $entry,
            start_time    => $entry->start_time,
            stop_time     => $entry->stop_time,
        );
    }
};

=head2 0.0.2

Converted the original L<Qublog::Model::JournalEntry> object descriptions into comments.

=cut

since '0.0.2' => sub {
    my $entries = Qublog::Model::JournalEntryCollection->new;
    $entries->unlimit;

    my $dbh = Jifty->handle->dbh;

    my $comment = Qublog::Model::Comment->new;
    while (my $entry = $entries->next) {
        if (not $entry->start_time) {
            $entry->delete;
            next;
        }
        
        my $stop_time    = $entry->stop_time || $entry->start_time;
        my $time_diff    = $stop_time - $entry->start_time;
        my $average_time = $entry->start_time + $time_diff * 0.5;

        #warn "-----------------------\n";
        #warn "start_time   = ".$entry->start_time->hms."\n";
        #warn "average_time = ".$average_time->hms."\n";
        #warn "stop_time    = ".$stop_time->hms."\n";

        my $description = $dbh->selectrow_array(
            "SELECT description FROM journal_entries WHERE id = ".$entry->id);

        $comment->create(
            journal_entry => $entry,
            name          => $description,
            created_on    => $average_time,
        );
    }
};

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
