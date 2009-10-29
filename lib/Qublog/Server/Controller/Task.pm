package Qublog::Server::Controller::Task;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

Qublog::Server::Controller::Task - Task manager for Qublog

=head1 DESCRIPTION

This displays the project screen and task viewer, such as they are.

=head1 METHODS

=head2 begin

Check for login.

=cut

sub begin :Private {
    my ($self, $c) = @_;
    $c->forward('/user/check');
}

=head2 index

Show all the projects and tasks attached to them.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $user = $c->user->get_object;

    $c->stash->{task_filter} = $c->model('DB::Task')->search_current($user);
    $c->stash->{projects}    = $c->stash->{task_filter}->search({
        task_type => 'project',
    });

    $c->stash->{template} = '/task/index';
}

=head2 edit

Edit an individual task.

=cut

sub edit :Local :Args(1) {
    my ($self, $c, $task_id) = @_;

    my $task = $c->model('DB::Task')->find($task_id);

    $c->dispatch('default') unless $task;

    $c->stash->{task}     = $task;
    $c->stash->{template} = '/task/edit';
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
