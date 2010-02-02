package Qublog::Server::Controller::Compat;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Qublog::Schema::Action::CreateThingy;

=head1 NAME

Qublog::Server::Controller::Compat - Catalyst Controller

=head1 DESCRIPTION

This is a temporary controller that I hope to eliminate once I have a better way
of dealing with forms in place. This is named "compat" because it's really a
kludge to make everything from the old Jifty version of Qublog work. It will go
away soon.

=head1 METHODS

=head2 begin

Check for login.

=cut

sub begin :Private {
    my ($self, $c) = @_;
    $c->forward('/user/check');
}

=head2 comment/delete

Delete a comment.

=cut

sub delete_comment :Path('comment/delete') :Args(1) {
    my ($self, $c, $comment_id) = @_;

    my $comment = $c->model('DB::Comment')->find($comment_id);
    if (!$comment) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'unable to delete that comment',
        };
        
        return $c->detach('return');
    }

    if ($comment->owner->id != $c->user->get_object->id) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'you may not delete that comment',
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
            message => 'unable to stop that timer',
        };
        
        return $c->detach('return');
    }

    if ($entry->owner->id != $c->user->get_object->id) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'you may not stop that timer',
        };
    }

    $entry->stop_timer;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => sprintf('stopped the timer for %s', $entry->name),
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
            message => 'unable to start that timer',
        };
        
        return $c->detach('return');
    }

    if ($entry->owner->id != $c->user->get_object->id) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'you may not start that timer',
        };
    }

    $entry->start_timer;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => sprintf('started the timer for %s', $entry->name),
    };

    $c->detach('return');
}

=head2 journal_timer/change

Change the start or stop time of a timer.

=cut

sub change_start_stop_journal_timer :Path('journal_timer/change') :Args(2) {
    my ($self, $c, $which, $journal_timer_id) = @_;

    return $c->detach('return') if $c->request->params->{cancel};

    my $journal_timer = $c->model('DB::JournalTimer')->find($journal_timer_id);
    my $req = $c->request;

    my $cancel = $req->params->{cancel};
    return $c->detach('return') if $cancel;

    my $get_time = "${which}_time";
    my $new_time = $req->params->{new_time};
    my $date_too = $req->params->{date_too};
    if (not $new_time) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'please enter a new time',
        };
        return $c->detach('continue');
    }

    my $new_datetime;
    if ($date_too) {
        $new_datetime = Qublog::DateTime->parse_human_datetime($new_time, $c->time_zone);
    }
    else {
        my $context = $journal_timer->$get_time;
        $new_datetime = Qublog::DateTime->parse_human_time($new_time, $c->time_zone, $context);
    }

    if (not $new_datetime) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'unable to understand your date',
        };
        return $c->detach('continue');
    }

    $journal_timer->$get_time($new_datetime);
    $journal_timer->update;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => "updated the $which time",
    };

    $c->detach('return');
}

=head2 journal_entry/update

Update the journal entry.

=cut

sub update_journal_entry :Path('journal_entry/update') :Args(1) {
    my ($self, $c, $journal_entry_id) = @_;

    return $c->detach('return') if $c->request->params->{cancel};

    my $journal_entry = $c->model('DB::JournalEntry')->find($journal_entry_id);

    my $name         = $c->request->params->{name};
    $name =~ s/^\s+//; $name =~ s/\s+$//;
    if (not $name) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'please set the name',
        };
        return $c->detach('continue');
    }

    my $primary_link = $c->request->params->{primary_link};

    my $project_id   = $c->request->params->{project};
    my $project      = $c->model('DB::Task')->find($project_id);
    if (not $project) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'please choose a project',
        };
        return $c->detach('continue');
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

    return $c->detach('return') if $c->request->params->{cancel};

    eval {
        $c->model('DB')->txn_do(sub {
            my $comment = $c->model('DB::Comment')->find($comment_id);
            die "no such comment\n" unless $comment;

            my $date_too   = $c->request->params->{date_too};
            my $created_on = $c->request->params->{created_on};

            die "no time value given\n" unless $created_on;

            if ($date_too) {
                $created_on = Qublog::DateTime->parse_human_datetime($created_on, $c->time_zone);
            }
            else {
                $created_on = Qublog::DateTime->parse_human_time(
                    $created_on, $c->time_zone, $comment->created_on);
            }

            die Qublog::DateTime->human_error . "\n" 
                unless Qublog::DateTime->human_success;

            my $name = $c->request->params->{name};

            my $create_thingy = Qublog::Schema::Action::CreateThingy->new(
                schema       => $c->model('DB')->schema,
                today        => $c->today,
                owner        => $c->user->get_object,
                comment      => $comment,
                comment_text => $name,
            );
            $create_thingy->process;

            $comment->created_on($created_on);
            $comment->update;
        });
    };

    if ($@) {
        my $ERROR = $@;
        $ERROR =~ s/^DBIx::Class::Schema::txn_do\(\):\s+//g;
        $ERROR =~ s/\n+$//g;
        push @{ $c->flash->{messages} }, {
            type    => 'info',
            message => "unable to change your comment: $ERROR",
        };
    }

    else {
        push @{ $c->flash->{messages} }, {
            type    => 'info',
            message => 'changed your comment',
        };
    }

    $c->detach('return');
}

=head2 set_task_status

Update the status of the task.

=cut

sub set_task_status :Path('task/set/status') :Args(2) {
    my ($self, $c, $task_id, $status) = @_;
    my $task = $c->model('DB::Task')->find($task_id);

    unless ($status =~ /^(?:nix|done|open)$/) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => "please select a status to set",
        };
        return $c->detach('return');
    }

    $task->status($status);
    $task->update;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => sprintf('marked task #%s as %s', $task->tag, $status),
    };

    $c->detach('return');
}

=head2 new_task

Create a new task.

=cut

sub new_task :Path('task/new') {
    my ($self, $c) = @_;
    my $name = $c->request->params->{name};

    unless ($name) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'you must enter the description for the task',
        };
        return $c->detach('return');
    }

    my ($tag_name) =~ s/^\s*#(\w+):\s*//;

    my $task = $c->model('DB::Task')->create({
        name  => $name,
        owner => $c->user->get_object,
    });
    $task->add_tag($tag_name) if $tag_name;

    push @{ $c->flash->{messages} }, {
        type    => 'info',
        message => sprintf('added a new task with tag #%s to project #%s', 
            $task->tag, $task->project->tag),
    };

    $c->detach('return');
}

=head2 update_task

Update a task.

=cut

sub update_task :Path('task/update') :Args(1) {
    my ($self, $c, $task_id) = @_;

    my $task = $c->model('DB::Task')->find($task_id);
    unless ($task) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Please select a task to update.',
        };
        return $c->detach('continue');
    }

    my $tag_name = $c->request->params->{tag_name};
    unless ($tag_name) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Please enter a tag name.',
        };
        return $c->detach('continue');
    }

    my $name = $c->request->params->{name};
    unless ($name) {
        push @{ $c->flash->{messages} }, {
            type    => 'error',
            message => 'Please enter the name of the task.',
        };
        return $c->detach('continue');
    }

    $task->name($name);
    $task->update;

    $task->add_tag($tag_name) unless $task->has_tag($tag_name);

    $c->detach('return');
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

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 LICENSE

Qublog Personal/Professional Journaling
Copyright (C) 2009  Andrew Sterling Hanenkamp

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
