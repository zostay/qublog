package Qublog::Server::View::TD::Form;

use strict;
use warnings;

use Template::Declare::Tags;

use Qublog::Web;
use Qublog::Server::View::Common;

template 'form/change_start_stop' => sub {
    my ($self, $c) = @_;
    my $timer  = $c->stash->{journal_timer};

    my $fields = $c->field_defaults({
        which    => 'start',
        new_time => '-', 
        origin   => $c->request->uri,
        date_too => 0,
    });

    if ($fields->{new_time} eq '-') {
        $fields->{new_time} = Qublog::DateTime->format_human_time(
            $fields->{which} eq 'start' ? $timer->start_time 
          :                               $timer->stop_time
        );
    }

    form {
        {
            method is 'POST',
            action is '/compat/journal_timer/change/' 
                . $fields->{which} . '/' . $timer->id,
        }

        input {
            type is 'hidden',
            name is 'origin',
            value is $fields->{origin},
        };

        label { attr { for => 'new_time' } 'New time' };
        input {
            type is 'text',
            name is 'new_time',
            class is 'text',
            value is $fields->{new_time},
        };

        input {
            {
                type is 'checkbox',
                name is 'date_too',
                class is 'checkbox',
                value is 1,
            }

            if ($fields->{date_too}) {
                checked is $fields->{date_too};
            }

            undef;
        };
        label { attr { for => 'date_too', class => 'checkbox' }; 'Change date too?' };

        div { { class is 'submit' }
            input {
                type is 'submit',
                name is 'submit',
                value is "Set \u$fields->{which} Time",
            };
            input {
                type is 'submit',
                name is 'cancel',
                value is 'Cancel',
            };
        };
    };
};

template 'form/edit_entry' => sub {
    my ($self, $c) = @_;
    my $entry = $c->stash->{journal_entry};

    my $fields = $c->field_defaults({
        name         => $entry->name,
        primary_link => $entry->primary_link,
        project      => $entry->project->id,
    });

    form {
        {
            method is 'POST',
            action is '/compat/journal_entry/update/' . $entry->id,
        }

        label { attr { for => 'name' }; 'Name' };
        input {
            type is 'text',
            name is 'name',
            value is $fields->{name},
        };

        label { attr { for => 'primary_link' }; 'Primary link' };
        input {
            type is 'text',
            name is 'primary_link',
            value is $fields->{primary_link},
        };

        label { attr { for => 'project' }; 'Project' };
        select { { name is 'project' }

            my $projects = $c->model('DB::Task')->search({
                task_type => 'project',
                status    => 'open',
            }, { order_by => { -desc => 'created_on' } });

            while (my $project = $projects->next) {
                option { 
                    { value is $project->id }

                    if ($project->id == $fields->{project}) {
                        selected is 'selected';
                    }

                    '#' . $project->tag . ': ' . $project->name
                };
            }
        };

        div { { class is 'submit' }
            input { 
                type is 'submit',
                name is 'submit',
                value is 'Save',
            };

            input {
                type is 'submit',
                name is 'cancel',
                value is 'Cancel',
            };
        };
    };
};

template 'form/list_actions/project_summary' => sub {
    my ($self, $c, $project) = @_;

    my $tasks = $project->children({ status => 'open' });
    ul { { class is 'project-summary' }
        while (my $task = $tasks->next) {
            li {
                {
                    id is 'summary-'.$task->tag,
                    class is 'subject icon o-task a-'.$task->task_type,
                }
                span { { class is 'nickname' }
                    '#'.$task->tag.':'
                };
                outs ' ';
                span { { class is 'name' }
                    outs_raw htmlify($task->name, $c);
                };

                if ($task->task_type ne 'action') {
                    show './project_summary', $c, $task;
                }
            };
        }
    };
};

template 'form/list_actions' => sub {
    my ($self, $c) = @_;
    my $entry = $c->stash->{journal_entry};
    
    form { { method is 'GET', action is $c->request->uri_with({ form => undef }) }
        show './list_actions/project_summary', $c, $entry->project;

        input {
            type is 'submit',
            name is 'submit',
            value is 'Close',
        };
    };
};

template 'form/edit_comment' => sub {
    my ($self, $c) = @_;
    my $comment = $c->stash->{comment};

    my $fields = $c->field_defaults({
        created_on => Qublog::DateTime->format_human_time($comment->created_on),
        name       => $comment->name,
        return_to  => $c->request->uri_with({ form => undef }),
        origin     => $c->request->uri_with({ form => undef }),
    });

    form { 
        { 
            method is 'POST', 
            action is $c->uri_for('/compat/comment/update', $comment->id) 
        }

        label { attr { for => 'created_on' }; 'Created on' };
        input {
            type is 'text',
            name is 'created_on',
            value is $fields->{created_on},
        };

        label { attr { for => 'name' }; 'Name' };
        textarea { { name is 'name' } $fields->{name} };

        input {
            type is 'checkbox',
            class is 'checkbox',
            name is 'date_too',
            value is 1,
        };
        label { attr { for => 'date_too', class => 'checkbox' }; 'Set the date too?' };

        input {
            type is 'hidden',
            name is 'return_to',
            value is $fields->{return_to},
        };

        div { { class is 'submit' }
            input {
                type is 'submit',
                name is 'submit',
                value is 'Save',
            };

            input {
                type is 'submit',
                name is 'cancel',
                value is 'Cancel',
            };
        };
    };
};

1;
