package Qublog::Server::View::TD::Form;
use Template::Declare::Tags;

use Qublog::Server::View::Common;

template 'form/change_start_stop' => sub {
    my ($self, $c) = @_;
    my $timer  = $c->stash->{journal_timer};

    my $time = $fields->{which} eq 'start' ? $timer->start_time : $timer->stop_time;

    my $fields = $c->field_defaults({
        which           => 'start',
        new_time        => Qublog::DateTime->format_human_time($time),
        origin          => $c->request->uri,
        change_date_too => 0,
    });

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
            value is $fields->{new_time},
        };

        input {
            type is 'checkbox',
            name is 'change_date_too',
            value is 1,
            checked is $fields->{change_date_too},
        };
        label { attr { for => 'change_date_too' }, 'Change date too?' };

        input {
            type is 'submit',
            name is 'submit',
            value is "Set \u$which Time",
        };
        input {
            type is 'submit',
            name is 'cancel',
            value is 'Cancel',
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
        select {
            name is 'project',

            my $projects = $c->model('DB::Task')->search({
                task_type => 'project',
                status    => 'open',
            });

            while (my $project = $projects->next) {
                option { 
                    { 
                        value is $project->id,
                        selected is $project->id == $fields->{project},
                    }

                    '#' . $project->tag . ': ' . $project->name
                };
            }
        };

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
                    outs_raw htmlify($task->name);
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
            type is 'hidden',
            name is 'return_to',
            value is $fields->{return_to},
        };

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

1;
