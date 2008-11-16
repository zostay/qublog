use strict;
use warnings;

=head1 NAME

Qublog::Action::CreateJournalThingy

=cut

package Qublog::Action::CreateJournalThingy;
use base qw/Qublog::Action Jifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param task_entry =>
        label is 'On',
        is mandatory,
        default is defer {
            my $timers = Qublog::Model::JournalTimerCollection->new;
            $timers->unlimit;
            $timers->order_by( { column => 'start_time', order => 'des' } );
            
            if ($timers->count > 0) {
                return $timers->first->journal_entry->name;
            }
            else {
                return '';
            }
        },
        ;

    param comment =>
        type is 'textarea',
        label is 'Comment',
        is mandatory,
        is focus,
        ;
};

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    
    # What kind of entry are we making?
    my $task_entry = $self->argument_value('task_entry');
    my $thingy = $self->prepare_thingy( task_entry => $task_entry );

    if ($thingy->isa('Qublog::Model::Task')) {
        $self->take_task_action($thingy);
    }
    elsif ($thingy->isa('Qublog::Model::JournalTimer')) {
        $self->take_timer_action($thingy);
    }
    elsif ($thingy->isa('Qublog::Model::JournalEntry')) {
        $self->take_entry_action($thingy);
    }
    else {
        die "I don't know what happened, but it was bad.";
    }
}

=head2 take_task_action TASK

If the given TASK is empty, a new task will be created using L</comment> as the task's name. If the given TASK is initialized, a comment will be added to that task.

=cut

sub take_task_action {
    my ($self, $task) = @_;

    # Add a comment to an existing task
    if ($task->id) {
        eval {
            my $comment = $self->_do_it(
                CreateComment => {
                    journal_day => Qublog::Model::JournalDay->for_today,
                    name        => $self->argument_value('comment'),
                },
            );

            $self->_do_it(
                CreateTaskLog => {
                    task     => $task,
                    log_type => 'note',
                    comment  => $comment,
                },
            );

            $self->result->message(
                _('Added a comment to task %1.', 
                    $self->argument_value('task_entry'))
            );
        };
    }

    # Create a new task
    else {
        my $nickname = $self->nickname('short');

        eval {
            $self->_do_it( 
                CreateTask => {
                    custom_nickname => $nickname,
                    name            => $self->argument_value('comment'),
                    task_type       => 'action',
                    status          => 'open',
                    parent          => Qublog::Model::Task->project_none,
                } 
            );

            $self->result->message(
                _('Created a new task %1.',
                    $self->argument_value('task_entry'))
            );
        };

        if ($@) { $self->log->error($@) }
    }
}

=head2 take_timer_action TIMER

Given an initialized L<Qublog::Model::JournalTimer>, this adds a new comment to that timer.

=cut

sub take_timer_action {
    my ($self, $timer) = @_;

    eval {
        $self->_do_it(
            CreateComment => {
                journal_day   => Qublog::Model::JournalDay->for_today,
                journal_timer => $timer,
                name          => $self->argument_value('comment'),
            },
        );

        $self->result->message(
            _('Added a new comment to the current timer.'),
        );
    };
}

=head2 take_entry_action ENTRY

Given a L<Qublog::Model::JournalEntry>, this action will start a new entry if ENTRY is not initialized or restart an entry if it is. It will then add a comment to the new timer.

=cut

sub take_entry_action {
    my ($self, $entry) = @_;

    eval {

        # Restart an existing entry
        my ($timer, $message);
        if ($entry->id) {
            $timer   = $entry->start_timer;
            $message = _('Restarted %1 and added your comment.', $entry->name);
        }

        # Start a new entry
        else {
            my $nickname = $self->nickname('short');
            my $task = Qublog::Model::Task->new;
            $task->load_by_nickname($nickname) if $nickname;

            $entry = $self->_do_it(
                CreateJournalEntry => {
                    journal_day => Qublog::Model::JournalDay->for_today,
                    name        => $self->argument_value('task_entry'),
                    project     => $task,
                },
            );

            $timer   = $entry->timers->first;
            $message = _('Started %1 and added your comment.', $entry->name);
        }

        $self->_do_it(
            CreateComment => {
                journal_day   => Qublog::Model::JournalDay->for_today,
                journal_timer => $timer,
                name          => $self->argument_value('comment'),
            },
        );

        $self->result->message($message);
    };
}

=head2 nickname [ SHORT ]

Checks to see if the the first part of the L</task_entry> is a nickname in #abc format. If it is, returns the nickname. Otherwise, returns C<undef>.

The optional argument is a boolean value. If true, this tells the method to return the shortened nickname (without the "#" in front).

=cut

sub nickname {
    my ($self, $short) = @_;

    # Clean up the task/entry "title"
    my $title = $self->argument_value('task_entry');
    $title =~ s/^\s+//; $title =~ s/\s+$//;

    # Try to extract a nickname 
    my $extractor = $short ? qr/^#(\w+)/ : qr/^(#\w+)/;
    my ($nickname) = $title =~ /$extractor/;

    return $nickname;
}

=head2 prepare_thingy

Given named arguments, it looks at C<task_entry> and determines what object the comment should be attached to. The return values are as follows:

=over

=item Loaded L<Qublog::Model::Task>

This indicates that the comment should just be attached to the task and not to any entry.

=item Empty L<Qublog::Model::Task>

This indicates that the comment should just be attached to a task that hasn't been created yet.

=item Loaded L<Qublog::Model::JournalTimer>

This indicates that the comment should be added to this running timer. The timer will not need to be modified.

=item Loaded L<Qublog::Model::JournalEntry>

This indicates that the comment should be added to a new timer attached to this entry.

=item Empty L<Qublog::Model::JournalEntry>

This indicates that we will need to create a journal entry, create a journal timer and attach it, and create a comment to attach to that.

=back

=cut

sub prepare_thingy {
    my ($self) = @_;

    my $title    = $self->argument_value('task_entry');
    my $nickname = $self->nickname;

    # Is the nickname the title? Task comment create; no entry or timer
    if (defined $nickname and $nickname eq $title) {
        my $nickname_only = $self->nickname('short');

        my $task = Qublog::Model::Task->new;
        $task->load_by_nickname( $nickname_only );

        return $task;
    }

    # Otherwise, we're trying to create an entry/timer/comment
    else {

        # Get the current day; we'll use it to find timers
        my $day = Qublog::Model::JournalDay->for_date( Jifty::DateTime->today );

        # Does the title match a running entry?
        {
            my $entries = Qublog::Model::JournalEntryCollection->new;
            $entries->limit( 
                column => 'journal_day', 
                value  => $day,
            );
            $entries->limit(
                column => 'name',
                value  => $title,
            );
            $entries->limit_by_running;
            $entries->order_by( { column => 'start_time', order => 'DES' } );
            if ($entries->count > 0) {
                my $timers = $entries->first->timers;
                $timers->limit_by_running;
                $timers->order_by( { column => 'start_time', order => 'DES' } );
                my $timer = $timers->first;
                return $timer if $timer;
            }
        }

        # Does the title match an existing entry?
        {
            my $entries = Qublog::Model::JournalEntryCollection->new;
            $entries->limit( 
                column => 'journal_day', 
                value  => $day,
            );
            $entries->limit(
                column => 'name',
                value  => $title,
            );
            return $entries->first || Qublog::Model::JournalEntry->new;
        }
    }
}

=cut

=head2 thingy_button

Given named arguments, it looks at C<task_entry> and determines what the button on the UI should read. This is executed from L<Qublog::Dispatcher/journal/thingy_button>.

=cut

sub thingy_button {
    my ($self) = @_;

    # This should *ALWAYS* return a blessed thingy... we're screwed otherwise
    my $thingy = $self->prepare_thingy;

    # Is this just a task comment
    if ($thingy->isa('Qublog::Model::Task')) {

        # To an initialize comment?
        return 'Comment' if $thingy->id;

        # We going to create it!
        return 'Taskinate';
    }
    
    # Post to a timer
    elsif ($thingy->isa('Qublog::Model::JournalTimer')) {
        return 'Post';
    }

    # Post to a timer after we start it
    elsif ($thingy->isa('Qublog::Model::JournalEntry')) {

        # Post to a timer on a current entry
        return 'Restart' if $thingy->id;

        # Post to a timer on a new entry
        return 'Start';
    }

    # WTF? A new entry? Maybe?
    else {
        return 'Start';
    }
}

=head2 _do_it CLASS => ARGUMENTS

Builds the record action given by CLASS and passes ARGUMENTS. Sets the result to the action's message and dies if the action result is a failure. On success, it returns the value in the record method for the class after running the action.

=cut

sub _do_it {
    my ($self, $class, $arguments) = @_;

    my $action = Jifty->web->new_action(
        class     => $class,
        arguments => $arguments,
    );

    $action->run;

    if ($action->result->failure) {
        $self->result->error($action->result->message);
        die $action->result->message;
    }

    return $action->record;
}

1;

