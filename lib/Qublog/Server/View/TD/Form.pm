package Qublog::Server::View::TD::Form;

use strict;
use warnings;

use Template::Declare::Tags;

use Qublog::Web;
use Qublog::Server::View::Common;

=head1 NAME

Qublog::Server::View::TD::Form - various form templates used with journal items

=head1 DESCRIPTION

Journal items may have forms attached to them by actions. This contains those
forms.

=head1 TEMPLATES

=head2 form/change_start_stop

This displays a form for changing the start or stop time of a timer. It expects
the following stash arguments:

=over

=item journal_timer

This is the L<Qublog::Schema::Result::JournalTimer> to edit.

=back

The request for this form should include a C<which> argument, set to "start" or
"stop" to select which time on the timer to edit.

=cut

template 'form/change_start_stop' => sub {
    my ($self, $c) = @_;
    my $timer  = $c->stash->{journal_timer};

    my $which = $c->request->params->{which} || 'start';
    $which = 'start' unless $which eq 'start' or $which eq 'stop';

    form {
        {
            method is 'POST',
            action is '/api/model/journal_timer/change_' . $which . '/'
                . $which . '-' . $timer->id,
        }

        my $action_class = 'JournalTimer::Change' . ucfirst($which);
        my $action = $c->action_form(schema => $action_class => {
            record => $timer,
            id     => $timer->id,
        });
        $action->prefill_from_record;
        $action->setup_and_render(
            moniker => $which . '-' . $timer->id,
            globals => {
                origin => $c->request->uri_with({
                    form       => 'change_start_stop',
                    form_place => 
                        join('-', 'JournalTimer', $timer->id, $which),
                    comment    => $timer->id,
                }),
                return_to => $c->request->uri_with({
                    form       => undef,
                    form_place => undef,
                    form_type  => undef,
                    comment    => undef,
                }),
            },
        );

        div { { class is 'submit' }
            $action->render_control(button => {
                name  => 'submit',
                label => 'Save',
            });
            $action->render_control(button => {
                name  => 'cancel',
                label => 'Cancel',
            });
        };
    };
};

=head2 form/edit_entry

Show a form to edit a L<Qublog::Server::VIew::TD::Form>.

=over

=item journal_entry

The journal entry to edit.

=back

=cut

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
            action is '/api/model/journal_entry/update/edit_journal-' . $entry->id,
        }

        my $action = $c->action_form(schema => 'JournalEntry::Update' => {
            record => $entry,
        });
        $action->prefill_from_record;
        $action->setup_and_render(
            moniker => 'edit_journal-' . $entry->id,
            globals => {
                origin => $c->request->uri_with({
                    form          => 'edit_entry',
                    form_place    => $c->request->params->{form_place},
                    journal_entry => $entry->id,
                }),
                return_to => $c->request->uri_with({
                    form          => undef,
                    form_place    => undef,
                    form_type     => undef,
                    journal_entry => undef,
                }),
            },
        );

        div { { class is 'submit' }
            $action->render_control(button => {
                name  => 'submit',
                label => 'Save',
            });

            $action->render_control(button => {
                name  => 'cancel',
                label => 'Cancel',
            });
        };
    };
};

=head2 form/list_actions/project_summary

This is not meant to be used directly. This displays the tasks for a given
project.

See L</form/list_actions>.

=cut

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

=head2 form/list_actions

This shows the tasks for a journal entry's project.

Uses the following stashed arguments:

=over

=item journal_entry

This is the L<Qublog::Schema::Result::JournalEntry> to list actions for.

=back

=cut

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

=head2 form/edit_comment

Edit the timer and text of a comment.

Uses these stashed arguments:

=over

=item comment

This is the L<Qublog::Schema::Result::Comment> to edit.

=back

=cut

template 'form/edit_comment' => sub {
    my ($self, $c) = @_;
    my $comment = $c->stash->{comment};

    my $fields = $c->field_defaults({
        created_on => Qublog::DateTime->format_human_time(
            $comment->created_on, $c->time_zone),
        name       => $comment->name,
        return_to  => $c->request->uri_with({ form => undef }),
        origin     => $c->request->uri_with({ form => undef }),
    });

    form { 
        { 
            method is 'POST', 
            action is '/api/model/comment/update/edit_comment-'. $comment->id,
        }

        my $action = $c->action_form(schema => 'Comment::Update' => {
            record => $comment,
            id     => $comment->id,
        });
        $action->prefill_from_record;
        $action->setup_and_render(
            moniker => 'edit_comment-' . $comment->id,
            globals => {
                origin => $c->request->uri_with({
                    form       => 'edit_comment',
                    form_place => 'Comment-'.$comment->id,
                    form_type  => 'replace',
                    comment    => $comment->id,
                }),
                return_to => $c->request->uri_with({
                    form       => undef,
                    form_place => undef,
                    form_type  => undef,
                    comment    => undef,
                }),
            },
        );

        div { { class is 'submit' }
            $action->render_control(button => {
                name  => 'submit',
                label => 'Save',
            });
            $action->render_control(button => {
                name  => 'cancel',
                value => 'Cancel',
            });
        };
    };
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
