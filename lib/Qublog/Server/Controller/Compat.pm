package Qublog::Server::Controller::Compat;

use strict;
use warnings;
use parent 'Catalyst::Controller';

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
