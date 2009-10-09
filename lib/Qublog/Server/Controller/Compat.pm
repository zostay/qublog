package Qublog::Server::Controller::Compat;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Qublog::Schema::Action::CreateThingy;

=head1 NAME

Qublog::Server::Controller::Compat - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 comment/delete

Delete a comment.

=cut

sub delete_comment :Path('comment/delete') :Args(1) {
    my ($self, $c, $comment_id) = @_;

    my $comment = $c->model('DB::Comment')->find($comment_id);
    if (!$comment) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Unable to delete that comment.',
        };
        
        return $c->detach('return');
    }

    if ($comment->owner->id != $c->user->get_object->id) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'You may not delete that comment.',
        };
    }

    $comment->delete;
    $c->detach('return');
}

=head2 timer/stop

Stop the running timer.

=cut

sub stop_timer :Path('timer/stop') :Args(1) {
    my ($self, $c, $entry_id) = @_;

    my $entry = $c->model('DB::JournalEntry')->find($entry_id);
    if (!$entry) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Unable to stop that timer.',
        };
        
        return $c->detach('return');
    }

    if ($entry->owner->id != $c->user->get_object->id) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'You may not stop that timer.',
        };
    }

    $entry->stop_timer;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => sprintf('Stopped the timer for %s', $entry->name),
    };

    $c->detach('return');
}

=head2 timer/start

Stop the running timer.

=cut

sub start_timer :Path('timer/start') :Args(1) {
    my ($self, $c, $entry_id) = @_;

    my $entry = $c->model('DB::JournalEntry')->find($entry_id);
    if (!$entry) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Unable to start that timer.',
        };
        
        return $c->detach('return');
    }

    if ($entry->owner->id != $c->user->get_object->id) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'You may not start that timer.',
        };
    }

    $entry->start_timer;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => sprintf('Started the timer for %s', $entry->name),
    };

    $c->detach('return');
}

=head2 journal_timer/change

Change the start or stop time of a timer.

=cut

sub change_start_stop_journal_timer :Path('journal_timer/change') :Args(2) {
    my ($self, $c, $which, $journal_timer_id) = @_;
    my $journal_timer = $c->model('DB::JournalTimer')->find($journal_timer_id);
    my $req = $c->request;

    my $cancel = $req->params->{cancel};
    return $c->detach('return') if $cancel;

    my $get_time        = "${which}_time";
    my $new_time        = $req->params->{new_time};
    my $change_date_too = $req->params->{change_date_too};
    if (not $new_time) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Please enter a new time.',
        };
        return $c->detach('continue');
    }

    my $new_datetime;
    if ($change_date_too) {
        $new_datetime = Qublog::DateTime->parse_human_datetime($new_time);
    }
    else {
        my $context = $journal_timer->$get_time;
        $new_datetime = Qublog::DateTime->parse_human_time($new_time, $context);
    }

    if (not $new_datetime) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Unable to understand your date.',
        };
        return $c->detach('continue');
    }

    $journal_timer->$get_time($new_datetime);
    $journal_timer->update;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => "Updated the $which time.",
    };

    $c->detach('return');
}

=head2 journal_entry/update

Update the journal entry.

=cut

sub update_journal_entry :Path('journal_entry/update') :Args(1) {
    my ($self, $c, $journal_entry_id) = @_;
    my $journal_entry = $c->model('DB::JournalEntry')->retrieve($journal_entry_id);

    my $name         = $c->request->params->{name};
    $name =~ s/^\s+//; $name =~ s/\s+$//;
    if (not $name) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Please set the name.',
        };
        return $c->detach('continue');
    }

    my $primary_link = $c->request->params->{primary_link};

    my $project_id   = $c->request->params->{project};
    my $project      = $c->model('DB::Task')->retrieve($project_id);
    if (not $project) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Please choose a proejct.',
        };
    }

    $journal_entry->name( $name );
    $journal_entry->primary_link( $primary_link );
    $journal_entry->project( $project );
    $journal_entry->update;

    $c->detach('return');
}

=head2 comment/update

Update a comment.

=cut

sub update_comment :Path('comment/update') :Args(1) {
    my ($self, $c, $comment_id) = @_;
    my $comment = $c->model('DB::Comment')->retrieve($comment_id);

    my $created_on = $c->request->params->{created_on};

    my $name = $c->request->params->{name};

    $c->detach('return');
}

=head2 thingy/new

Create a new journal thingy.

=cut

sub new_thingy :Path('thingy/new') {
    my ($self, $c) = @_;

    my $title = $c->request->params->{task_entry};
    if (not $title) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'You must make an entry in the "On" box.',
        };
        return $c->detach('continue');
    }

    my $comment = $c->request->params->{comment};
    if (not $comment) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'You must make an entry in the comment box.',
        };
        return $c->detach('continue');
    }

    my $thingy;

    $title =~ s/^\s+//; $title =~ s/\s+$//;
    my ($nickname, $short_nickname) = $title =~ /^(#(\w+))/;

    # Is the nickname the title? Task comment create; no entry or timer
    if (defined $nickname and $nickname eq $title) {
        $thingy = $c->model('DB::Task')->load_by_tag_name($short_nickname)
               || $c->model('DB::Task')->new;
    }

    # Otherwise, we're trying to create an entry/timer/comment
    else {

        # Get the current day; we'll use it to find timers
        my $day = $c->model('DB::JournalDay')->for_today;

        my $matching_entries = $c->model('DB::JournalEntry')->search({
            journal_day => $day,
            name        => $title,
        });

        # Does the title match a running entry?
        {
            my $entries = $matching_entries->search_by_running->search({}, { 
                order_by => { -desc => 'start_time' },
                rows     => 1,
            });

            if ($entries->count > 0) {
                my $timer = $entries->single->timers->search_by_running
                    ->search({}, {
                        order_by => { -desc => 'start_time' },
                        rows     => 1,
                    })->single;

                $thingy = $timer if $timer;
            }
        }

        # If we're still looking, does the title match en existing entry?
        unless ($thingy) {
            my $entries = $matching_entries->search({}, {
                order_by => { -desc => 'start_time' },
                rows     => 1,
            });

            $thingy = $entries->single || $entries->new({});
        }
    }

    my @args = ($thingy, $nickname, $short_nickname);
    if ($thingy->isa('Qublog::Schema::Result::Task')) {
        $c->forward('new_thingy_take_task_action', \@args);
    }
    elsif ($thingy->isa('Qublog::Schema::Result::JournalTimer')) {
        $c->forward('new_thingy_take_timer_action', \@args);
    }
    elsif ($thingy->isa('Qublog::Schema::Result::JournalEntry')) {
        $c->forward('new_thingy_take_entry_action', \@args);
    }
    else {
        die "I don't know what happened, but it was bad.";
    }

    $c->forward('return');
}

=head2 new_thingy_take_task_action

Create/update a task.

=cut

sub new_thingy_take_task_action :Private {
    my ($self, $c, $task, $nickname, $short_nickname) = @_;

    # Add a comment to an existing task
    if ($task->in_storage) {
        my $thingy_creator = Qublog::Schema::Action::CreateThingy->new(
            schema        => $c->model('DB')->schema,
            owner         => $c->user->get_object,
            comment_text  => $c->request->params->{comment},
        );
        $thingy_creator->process;

        $task->create_related('task_logs', {
            log_type => 'note',
            comment  => $thingy_creator->comment,
        });

        push @{ $c->flash->{messages} }, {
            type    => 'info',
            message => sprintf('Added a comment to task #%s.', $task->tag),
        };
    }

    else {
        $task->name($c->request->params->{comment});
        $task->task_type('action');
        $task->status('open');
        $task->parent($c->model('DB::Task')->project_none);
        $task->insert;

        $task->add_tag($nickname) if $nickname;

        push @{ $c->flash->{messages} }, {
            type    => 'info',
            message => sprintf('Added a new task #%s.', $task->tag),
        };
    }
}

=head2 new_thingy_take_timer_action

Add a new comment to a timer.

=cut

sub new_thingy_take_timer_action :Private {
    my ($self, $c, $timer, $nickname, $nickname_short) = @_;

    my $create_thingy = Qublog::Schema::Action::ScreateThingy->new(
        schema        => $c->model('DB')->schema,
        owner         => $c->user->get_object,
        journal_timer => $timer,
        comment_text  => $c->request->params->{comment},
    );
    $create_thingy->process;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => 'Added a new comment to the current time.',
    };
}

=head2 new_thingy_take_entry_action

Create a new entry or restart an existing one.

=cut

sub new_thingy_take_entry_action :Private {
    my ($self, $c, $entry, $nickname, $nickname_short) = @_;

    my ($timer, $message);

    # Restart the existing entry
    if ($entry->in_storage) {
        $timer   = $entry->start_timer;
        $message = sprintf('Restarted %s and added your comment.', $entry->name);
    }

    # Create and start a new entry
    else {
        my $task = $c->model('DB::Task')->find_by_tag_name($nickname);
        $task = $c->model('DB::Task')->project_none unless $task;

        $entry->journal_day($c->model('DB::JournalDay')->for_today);
        $entry->name($c->request->params->{task_entry});
        $entry->project($task);
        $entry->insert;

        $timer = $entry->start_timer;
        $message = sprintf('Started %s and added your comment.', $entry->name);
    }

    die "Failed to start a timer." unless $timer;

    my $create_thingy = Qublog::Schema::Action::CreateThingy->new(
        schema        => $c->model('DB')->schema,
        owner         => $c->user->get_object,
        journal_timer => $timer,
        comment_text  => $c->request->params->{comment},
    );
    $create_thingy->process;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => $message,
    };
}

=head2 return

Private routine to redirect according to the C<return_to> parameter. Without that parameter, defaults to the main journal page.

=cut

sub return :Private {
    my ($self, $c) = @_;
    my $return_to = $c->request->params->{return_to};
    $return_to  ||= $c->uri_for('/journal');
    $c->response->redirect($return_to);
}

=head2 continue

Private routine to redirect according to the C<origin> parameter. Without that parameter it defaults to the journal.

=cut

sub continue :Private {
    my ($self, $c) = @_;
    my $origin = $c->request->params->{origin};
    $origin ||= $c->uri_for('/journal');
    $c->response->redirect($origin);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
