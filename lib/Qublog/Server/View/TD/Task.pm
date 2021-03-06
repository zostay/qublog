package Qublog::Server::View::TD::Task;
use strict;
use warnings;

use Qublog::Server::View::Common;
use Qublog::Web;

use Template::Declare::Tags;

=head1 NAME

Qublog::Server::View::TD::Task - Task-related templates

=head1 DESCRIPTION

This class defines the templates for task views.

=head1 TEMPLATES

=head2 task/index

This lists all the projects, groups, and actions for a user.

=cut

template 'task/index' => sub {
    my ($self, $c) = @_;

    $c->stash->{title} = 'Projects';

    $c->add_style( file => 'tasks' );

    page {
        div { { class is 'top-spacer' }
            show './new', $c;
        };

        show './list', $c, {
            children    => $c->stash->{projects}, 
            task_filter => $c->stash->{task_filter},
        };
    } $c;
};

=head2 task/new

Present a small form for creating new tasks.

=cut

template 'task/new' => sub {
    my ($self, $c) = @_;

    div { { class is 'new_task' }
        form { { action is '/compat/task/new', method is 'POST' }
            label { attr { for => 'name' }; 'New task:' };
            input {
                type is 'text',
                class is 'text',
                name is 'name',
            };

            input {
                type is 'hidden',
                name is 'return_to',
                value is $c->request->uri,
            };

            div { { class is 'submit' }
                input {
                    type is 'submit',
                    name is 'submit',
                    value is 'Create',
                };
            };
        };
    };
};

=head2 task/list

List all the children of a task.

=cut

template 'task/list' => sub {
    my ($self, $c, $args) = @_;
    my $tasks       = $args->{children};
    my $task_filter = $args->{task_filter};
    my $seen        = $args->{seen} || {};

    # Show tasks if there are any
    if ($tasks->count > 0) {
        while (my $task = $tasks->next) {
            next if $seen->{ $task->id }; # avoid infinite recursion
            $seen->{ $task->id }++;

            show './view', $c, { 
                task        => $task,
                recursive   => 1,
                task_filter => $task_filter,
                seen        => $seen,
            };
        }
    }

    # Show an empty message if none
    else {
        p { { class is 'empty' } 'No tasks found.' };
    }
};

=head2 task/view

View a single task.

=cut

template 'task/view' => sub {
    my ($self, $c, $args) = @_;
    my $task = $args->{task};

    # Show a droppable box for top level projects
    div { { class is 'top_level' } 'Top-level Project' }
        if $task->task_type eq 'project';

    my @classes = ('task', $task->task_type, $task->status);
    push @classes, 'none-project' if $task->is_none_project;
    
    # Show the task
    div {
        {
            id is 'task-'.$task->id,
            class is join(' ', @classes),
        }

        # Show actions unless this is "none", which shouldn't be edited
        if (not $task->is_none_project) {

            div { { class is 'actions' }

                # Helper sub for creating the actions
                my $status_update = sub {
                    my ($label, $status, $confirm) = @_;
                    if ($task->status ne $status) {
                        hyperlink
                            label   => $label,
                            tooltip => sprintf("%s this task", $label),
                            class   => "icon only v-$status o-task",
                            confirm => $confirm,
                            action  => $c->uri_for('/compat/task/set/status', $task->id, $status, {
                                return_to => $c->request->uri,
                            }),
                            ;

                        outs ' ';
                    }
                };

                $status_update->('Nix',      'nix', 'Are you sure?');
                $status_update->('Complete', 'done');
                $status_update->('Re-open',  'open');

                hyperlink
                    label   => 'Edit',
                    tooltip => 'Edit this task',
                    class   => 'icon only v-edit o-task',
                    goto    => $c->uri_for('/task/edit', $task->id),
                    ;
            };
        }

        # Use a different header for each task type
        my $head_tag = $task->task_type eq 'project' ? \&h2
                     : $task->task_type eq 'group'   ? \&h3
                     :                                 \&h4
                     ;

        $head_tag->(sub {
            {
                id is $task->tag,
                class is 'icon a-project o-task subject',
            }

            span { { class is 'nickname' } '#'.$task->tag.':' };
            outs ' ';
            span { { class is 'name' } outs_raw htmlify($task->name, $c) };
        });

        # If this can have children (group or project) try to show them
        if ($args->{recursive} and $task->task_type ne 'action') {
            my $children = $args->{task_filter}->search({
                parent => $task->id,
            });
            
            show './list', $c, {
                children    => $children, 
                task_filter => $args->{task_filter},
                seen        => $args->{seen},
            };
        }
    };
};

=head2 task/edit

View the edit page for a task.

=cut

template 'task/edit' => sub {
    my ($self, $c) = @_;
    my $task = $c->stash->{task};

    $c->stash->{title} = $task->name;

    $c->add_style( file => 'tasks' );
    $c->add_style( file => 'journal' );

    $c->add_script( file => 'journal' );

    my $fields = $c->field_defaults({
        tag_name => $task->tag,
        name     => $task->name,
    });

    page {
        p {
            hyperlink
                label => 'Back to Tasks',
                class => 'icon v-return o-task',
                goto  => '/task',
                ;
        };

        div { { class is 'project-view inline' }
            form { 
                { 
                    method is 'POST',
                    action is '/compat/task/update/' . $task->id,
                }

                label { attr { for => 'tag_name' }; 'Tag' };
                input {
                    type is 'text',
                    name is 'tag_name',
                    class is 'text',
                    value is $fields->{tag_name},
                };

                label { attr { for => 'name' }; 'Name' };
                input {
                    type is 'text',
                    name is 'name',
                    class is 'text',
                    value is $fields->{name},
                };

                input {
                    type is 'hidden',
                    name is 'return_to',
                    value is $c->request->uri,
                };

                div { { class is 'submit' }
                    input {
                        type is 'submit',
                        name is 'submit',
                        value is 'Save',
                    };
                };
            };

            my $user        = $c->user->get_object;
            my $task_filter = $c->model('DB::Task')->search_current($user);
            my $children    = $task_filter->search({ parent => $task->id });

            show './list', $c, {
                children    => $children, 
                task_filter => $task_filter,
            };

            div { { class is 'journal' }
                show '/journal/bits/items', $c, $task;
            };
        };
    } $c;
};

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
