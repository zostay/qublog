use strict;
use warnings;

package Qublog::View;
use Jifty::View::Declare -base;

use Qublog::Web;
use Lingua::EN::Inflect qw/ PL /;
use List::Util qw/ max /;
use Scalar::Util qw/ reftype /;

=head1 NAME

Qublog::View - view templates for Qublog

=head1 METHODS

I have built some helper methods for use with Qublog.

=head2 show_links LINKS

This outputs the list of links given as an array in LINKS.

=cut

sub show_links(\@) {
    my $links = shift;

    div { { class is 'actions' }
        for my $link (@$links) {
            hyperlink %$link;
            outs ' ';
        }
    };
}

=head2 format_links LINKS

This formats the list of links given as an array in LINKS.

=cut

sub format_links(\@) {
    my $links = shift;

    my $content;
    Template::Declare->new_buffer_frame;
    {
        show_links @$links;
        $content = Template::Declare->buffer->data || '';
    }
    Template::Declare->end_buffer_frame;

    return $content;
}

=head2 popup_submit ARGS

This subroutine works exactly like C<form_submit>, except that it takes some additional options under the C<onclick> handler. This is intended to be used only within popup fragments.

=over

=item close_popup

If set to a true value, the popup region will be hidden.

=back

=cut

sub popup_submit(@) {
    my (%args) = @_;

    if (exists $args{onclick}) {

        my $replace_close = sub {
            my $handler = shift;
            if (exists $handler->{close_popup}) {
                my $close = delete $handler->{close_popup};
                if ($close) {
                    $handler->{refresh_self} = 1;
                    $handler->{replace_with} = '/__jifty/empty';
                    $handler->{effect}       = 'SlideUp';
                }
            }
        };
        
        if (reftype $args{onclick} eq 'ARRAY') {
            for my $handler (@{ $args{onclick} }) {
                $replace_close->($handler);
            }
        }

        elsif (reftype $args{onclick} eq 'HASH') {
            $replace_close->($args{onclick});
        }
    }

    return form_submit %args;
}

=head1 TEMPLATES

These are the templates used by Qublog.

=head2 JOURNAL PAGES

Herare the journal templates.

=head3 journal

Lists the journal entries associated with the current L<Qublog::Model::JournalDay>.

=cut

template 'journal' => page {
    my $day = get 'day';

    if ($day->is_today) {
        title is 'Journal';
    }
    else {
        title is 'Journal for '.format_date($day->datestamp)
    }

    render_region
        name      => 'journal_summary',
        path      => 'journal/summary',
        arguments => {
            date => $day->datestamp->ymd,
        },
        ;

    # Use journal/list to render the guts
    render_region 
        name      => 'journal_list',
        path      => 'journal/list', 
        arguments => {
            date => $day->datestamp->ymd,
        },
        ;
};

=head2 JOURNAL FRAGMENTS

=head3 journal/summary

Shows some handy information about the current day.

=cut

template 'journal/summary' => sub {
    my $day = get 'day';

    my $timers = $day->journal_timers;

    my $total_hours = 0;
    while (my $timer = $timers->next) {
        $total_hours += $timer->hours;
    }

    my $hours_left = 8 - $total_hours;

    my $quitting_time;
    my $is_today = $day->is_today;
    if ($is_today) {
        my $planned_duration = DateTime::Duration->new( hours => $hours_left );

        $quitting_time = Jifty::DateTime->now + $planned_duration;
    }

    div { 

        # Make some handy calculations
        my $js_time_format = 'eee MMM dd HH:mm:ss zzz yyy';
        my $load_time = Jifty::DateTime->now->format_cldr($js_time_format);

        # Throw some useful attributes into the top tag
        { 
            class is 'day-summary'.($is_today ? ' today' : ''),
            load_time  is $load_time,
            total_duration is $total_hours,
        }

        # Output the total duration for the current entry
        p { { class is 'duration so-far' }
            span { { class is 'number' } 
                sprintf '%.2f', $total_hours
            };
            span { { class is 'unit' } _('hours so far') };
        };

        p { { class is 'duration to-go' }
            span { { class is 'number' }
                sprintf '%.2f', max($hours_left, 0)
            };
            span { { class is 'unit' } _('hours to go') };
        };

        if ($quitting_time) {
            p { { class is 'clock summary' }
                span { { class is 'time' }
                    format_time $quitting_time;
                };
                span { { class is 'unit' } _('quitting time') };
            };
        }
    };
};

=head3 journal/list

A fragment for listing all the journal entries for a given date. Uses the date set in C<date>.

=cut

template 'journal/list' => sub {
    my $day = get 'day';

    # Show the Go to form
    div { { id is 'goto_date' }
        form {
            my $go_to_date = new_action class => 'GoToDate';
            render_action $go_to_date;
            form_submit
                label  => _('Go'),
                submit => $go_to_date,
                ;
        };
    };

    render_region
        name => 'new_comment_entry',
        path => 'journal/new_comment_entry',
        arguments => {
            date => $day->datestamp->ymd,
        },
        ;

    # Call journal/list_items to list all the timer spans
    render_region
        name => 'list_items',
        path => 'journal/list_items',
        arguments => {
            date => $day->datestamp->ymd,
        },
        ;
};

=head3 journal/new_entry

Uses the L<Qublog::Action::CreateJournalEntry> action to render a form for creating new entries.

=cut

template 'journal/new_entry' => sub {
    my $action = new_action
        class   => 'CreateJournalEntry',
        moniker => 'new_entry',
        ;

    # The create entry form
    div { { class is 'new_entry' }
        form {
            p { _('Start a new journal entry:') };
            render_action $action, [ qw/ name / ];
            form_submit
                label   => _('Start'),
                onclick => {
                    submit  => $action,
                    refresh => Jifty->web->current_region->parent,
                },
                ;
        };
    };
};

template 'journal/new_comment_entry' => sub {
    my $day = get 'day';

    my $action = new_action
        class   => 'CreateJournalThingy',
        moniker => 'new_entry',
        ;

    # Initial button name
    my $post_label = $day->journal_entries->count == 0 ? _('Start')
                   :                                     _('Post')
                   ;

    # The create entry form
    div { { class is 'new_comment_entry' }
        form {
            render_action $action, [ qw/ task_entry comment / ];
            form_submit
                class   => 'new_comment_entry_submit',
                label   => $post_label,
                onclick => {
                    submit  => $action,
                    refresh => Jifty->web->current_region->parent,
                },
                ;
        };
    };
};

=head3 journal/list_items

This lists all the timer spans for a given day.

=cut

template 'journal/list_items' => sub {
    my $day = get 'day';

    # Look up the appropriate timers
    my $timers = $day->journal_timers;

    # Don't show if none
    if ($timers->count > 0) {

        # Show the list
        div { { class is 'journal list' }
            while (my $entry_span = $timers->next) {

                # Show the view template if stopped
                if ($entry_span->is_stopped) {
                    show './view_entry_span', $entry_span;
                }

                # Show the edit template if running
                else {
                    show './edit_entry_span', $entry_span;
                }
            }
        };
    }

    # Show an empty message
    else {
        if ($day->is_today) {
            p { { class is 'empty' } _('No journal entries today.') };
        }
        else {
            p { { class is 'empty' } _('No journal entries %1.', $day->datestamp->ymd) };
        }
    }
};

=head3 journal/comments

This renders all the comments for a given timer span. This will show an edit form if the C<mode> is set to "edit" rather than "view".

=cut

template 'journal/comments' => sub {
    my $entry = get 'entry';
    my $timer = get 'timer';
    my $mode  = get 'mode';

    # Use list_comments to show the comments in this span
    render_region
        name => 'list_comments_'.$entry->id,
        path => 'journal/list_comments',
        arguments => {
            entry_id => $entry->id,
            timer_id => $timer->id,
        },
        ;
};

=head3 journal/new_comment

Show a form for posting a new comment to the span.

=cut

template 'journal/new_comment' => sub {
    my $entry = get 'entry';
    my $timer = get 'timer';

    my $action = new_action
        class   => 'CreateComment',
        moniker => 'new_comment',
        ;

    # Very simple form
    render_action $action, [ qw/ name / ];

    # with a complicated button
    form_submit
        label   => _('Post Comment'),
        onclick => {
            submit  => {
                action    => $action,
                arguments => {
                    journal_timer => $timer->id,
                },
            },
            refresh => Jifty->web->current_region->parent,
            arguments => {
                entry_id => $entry->id,
                mode     => 'edit',
                timer_id => $timer->id,
            },
        },
        ;
};

=head3 journal/list_comments

List all the comments belonging to the given timer span.

=cut

template 'journal/list_comments' => sub {
    my $entry_span = get 'timer';

    # Show the stopped time at the top
    if ($entry_span->is_stopped) {
        show './comment_item', {
            class     => 'stop-time',
            timestamp => $entry_span->stop_time,
            message   => _('Stopped timer.'),
            links     => [
                {
                    label   => _('Change'),
                    class   => 'icon change-time',
                    tooltip => _('Set the stop time for this timer span.'),
                    onclick => {
                        open_popup   => 1,
                        replace_with => 'journal/popup/change_start_stop',
                        arguments    => {
                            entry_id => $entry_span->journal_entry->id,
                            which    => 'stop',
                            timer_id => $entry_span->id,
                        },
                    },
                },
            ],
        };
    }

    # Show all the comments
    my $comments = $entry_span->comments;
    if ($comments->count > 0) {
        div { { class is 'comments list' }
            while (my $comment = $comments->next) {
                show './view_comment', $comment;
            }
        };
    }

    # Show the start time at the bottom
    show './comment_item', {
        class     => 'start-time',
        timestamp => $entry_span->start_time,
        message   => _('Started timer.'),
        links     => [
            {
                label   => _('Change'),
                class   => 'icon change-time',
                tooltip => _('Set the start time for this timer span.'),
                onclick => {
                    open_popup   => 1,
                    replace_with => 'journal/popup/change_start_stop',
                    arguments    => {
                        entry_id => $entry_span->journal_entry->id,
                        which    => 'start',
                        timer_id => $entry_span->id,
                    },
                },
            },
        ],
    };
};

=head2 JOURNAL PRIVATE TEMPLATES

=head3 journal/hours_summary

Shows the part of each journal entry containing the current number of hours that have been accumulated for this entry.

=cut

private template 'journal/hours_summary' => sub {
    my ($self, $entry_span) = @_;
    my $journal_entry = $entry_span->journal_entry;

    # Container for everything
    div { 

        # Make some handy calculations
        my $js_time_format = 'eee MMM dd HH:mm:ss zzz yyy';
        my $start_time = $entry_span->start_time->format_cldr($js_time_format);
        my $load_time  = Jifty::DateTime->now->format_cldr($js_time_format);
        my $total_duration = $journal_entry->hours;

        # Throw some useful attributes into the top tag
        { 
            class is 'hours-summary'
               .' '. ($journal_entry->is_running ? 'entry-running' 
                                                 : 'entry-stopped')
               .' '. ($entry_span->is_running    ? 'span-running'
                                                 : 'span-stopped'),
            start_time is $start_time,
            load_time  is $load_time,
            total_duration is $total_duration,
        }

        # Output the total duration for the current entry
        p { { class is 'duration total' }
            span { { class is 'number' } 
                sprintf '%.2f', $entry_span->journal_entry->hours 
            };
            span { { class is 'unit' } _('hours total') };
        };

        # Output the duration elapsed for the current timer
        p { { class is 'duration elapsed' }
            span { { class is 'number' } sprintf '%.2f', $entry_span->hours };
            span { { class is 'unit' } _('hours elapsed') };
        };
    };

    div { { class is 'related-tasks' }
        if ($entry_span->journal_entry->project->id) {
            show '/project/project_summary', $entry_span->journal_entry->project;
        }
    };
};

=head3 journal/view_entry_span TIMER

Show a view of the entry title, project, comments, etc. The TIMER argument is the L<Qublog::Model::JournalTimer> object this span should render for viewing.

=cut

private template 'journal/view_entry_span' => sub {
    my ($self, $entry_span) = @_;
    my $journal_entry = $entry_span->journal_entry;

    # Wrap it up with a bow
    div {
        { 
            id is 'span-'.$entry_span->id,
            class is 'entry entry-'.($journal_entry->id),
        }

        # Show the duration info
        show './hours_summary', $entry_span;

        # Show the button for reopening the entry
        div { { class is 'button-group' }
            form_submit
                label => _('Restart'),
                onclick => {
                    refresh_self => 1,
                    submit       => new_action(
                        class  => 'StartTimer',
                        record => $journal_entry,
                    ),
                },
                ;
        } if $journal_entry->is_stopped;

        div { { class is 'body' }

            h2 { { class is 'subject' } $journal_entry->name };

            p { { class is 'project' } 
                outs '(Project: ';
                hyperlink
                    label => $journal_entry->project->name,
                    url   => '/project#' . $journal_entry->project->nickname,
                    ;
                outs ')';
            } if $journal_entry->project->id;

            if ($journal_entry->primary_link) {
                hyperlink
                    class => 'link',
                    url   => $journal_entry->primary_link,
                    label => $journal_entry->primary_link,
                    ;
            }

            # Show all the comments for this entry span
            div { { class is 'description' } 
                render_region
                    name      => 'entry_comments_'.$entry_span->id,
                    path      => 'journal/comments',
                    arguments => {
                        entry_id => $journal_entry->id,
                        mode     => 'view',
                        timer_id => $entry_span->id,
                    },
                    ;
            };
        };
    };
};

=head3 journal/edit_entry_span TIMER

Show an editor for the subject, link, and project. Also show a form for posting new comments above the current comments in the span. The TIMER object is the L<Qublog::Model::JournalTimer> that this span should render.

=cut

private template 'journal/edit_entry_span' => sub {
    my ($self, $entry_span) = @_;
    my $journal_entry = $entry_span->journal_entry;

    div { 
        { 
            id is 'span-'.$entry_span->id,
            class is 'entry entry-'.($journal_entry->id),
        }
 
        # Show the duration
        show './hours_summary', $entry_span;

        my $action = new_action
            class   => 'UpdateJournalEntry',
            moniker => 'update_entry_'.$journal_entry->id,
            record  => $journal_entry,
            ;

        # Show various buttons for modifying the entry
        div { { class is 'button-group' }
            form_submit
                label   => _('Save'),
                onclick => {
                    refresh_self => 1,
                    submit       => $action,
                },
                ;

            form_submit
                label => _('Stop'),
                onclick => [
                    {
                        submit       => new_action(
                            class  => 'StopTimer',
                            record => $journal_entry,
                        ),
                        confirm      => 'Make sure to write down a synopsis of your progress in your physical log book.',
                    },
                    {
                        refresh_self => 1,
                    },
                    {
                        refresh   => Jifty->web->current_region->qualified_name
                                . '-entry_comments_'.$journal_entry->id,
                        arguments => { mode => 'view' },
                    },
                ],
                ;

            form_submit
                label => _('Delete'),
                onclick => {
                    refresh_self => 1,
                    confirm      => _("Are you sure you want to delete this entry?\n\nThis action cannot be undone."),
                    submit       => new_action(
                        class  => 'DeleteJournalEntry',
                        record => $journal_entry,
                    ),
                },
                ;

        };

        div { { class is 'body' }
            form {
                # Show the entry edit form (save button is above)
                render_action $action;

                # Show the list of comments
                render_region
                    name      => 'entry_comments_'.$journal_entry->id,
                    path      => 'journal/comments',
                    arguments => {
                        entry_id => $journal_entry->id,
                        mode     => 'edit',
                        timer_id => $entry_span->id,
                    },
                    ;

            };
        };
    };
};

=head3 journal/comment_item ARGUMENTS

Show a single comment item. The ARGUMENTS is a hashref with the following options:

=over

=item timestamp

This is a L<DateTime> object to display as the time of the comment.

=item message

This is a piece of text to render as the message of the comment. This will be interpreted by L<Text::Markdown>.

=item links

This list of links is preprocessed so that if C<open_popup> is set to true within an C<onclick> handler, the handler is modified to prop open the popup region correctly. This is then rendered as a list of links using L</show_links>. 

=back

=cut

private template 'journal/comment_item' => sub {
    my ($self, $args) = @_;

    my @links = not(defined($args->{links}))       ?  (                )
              : reftype($args->{links}) eq 'ARRAY' ? @{ $args->{links} } 
              :                                       ( $args->{links} )
              ;

    my $region = 'comment_'.Jifty->web->serial;
    for my $link (@links) {
        if (exists $link->{onclick}) {

            my $replace_close = sub {
                my $handler = shift;
                if (exists $handler->{open_popup}) {
                    my $open = delete $handler->{open_popup};
                    if ($open) {
                        $handler->{region} = Jifty->web->current_region->qualified_name.'-'
                                           . $region.'-actions',
                        $handler->{effect} = 'SlideDown';
                    }
                }
            };
            
            if (reftype $link->{onclick} eq 'ARRAY') {
                for my $handler (@{ $link->{onclick} }) {
                    $replace_close->($handler);
                }
            }

            elsif (reftype $link->{onclick} eq 'HASH') {
                $replace_close->($link->{onclick});
            }
        }
    }

    render_region
        name => $region,
        path => 'journal/comment_item_fragment',
        arguments => {
            class     => $args->{class},
            timestamp => format_time $args->{timestamp},
            message   => $args->{message},
            links     => scalar(@links) > 0 ? format_links @links : undef,
            tasks_for => $args->{tasks_for} ? $args->{tasks_for}->id : undef,
        },
        ;
};

template 'journal/comment_item_fragment' => sub {
    my $timestamp = get 'timestamp';
    my $message   = get 'message';
    my $links     = get 'links';
    my $tasks_for = get 'tasks_for';
    my $class     = get 'class';

    $class   = ' '.$class if defined $class;
    $class ||= '';

    my $comment = Qublog::Model::Comment->new;
    $comment->load($tasks_for) if $tasks_for;

    my $task_logs = $comment->task_logs if $comment->id;

    div { { class is 'comment'.$class }

        div { { class is 'date' }
            outs $timestamp;
        };

        outs_raw $links if $links;

        div { { class is 'comment_text' } 
            outs_raw htmlify($message, $task_logs);
        };

        render_region
            name => 'actions',
            path => '/__jifty/empty',
            ;
    };
};

=head3 journal/view_comment COMMENT

Given a comment object, it renders that comment.

=cut

private template 'journal/view_comment' => sub {
    my ($self, $comment) = @_;

    show './comment_item', {
        timestamp => $comment->created_on,
        message   => $comment->name,
        tasks_for => $comment,
    };

};

=head2 JOURNAL POPUPS

=head3 journal/popup/change_start_stop

This shows a popup editor for changing the start time or stop time of a entry span.

=cut

template 'journal/popup/change_start_stop' => sub {
    my $timer = get 'timer';
    my $which = get 'which';

    my $time = $which eq 'start' ? $timer->start_time : $timer->stop_time;
    my $action = new_action
        class     => 'ChangeTimer',
        record    => $timer,
        moniker   => "change_${which}_timer_".$timer->id,
        arguments => {
            which    => $which,
            new_time => format_time $time,
        },
        ;

    render_action $action, [ qw/ which new_time change_date / ];

    popup_submit
        label   => _("Set \u$which Time"),
        onclick => {
            submit      => $action,
            close_popup => 1,
        },
        ;

    popup_submit
        label   => _('Cancel'),
        onclick => {
            close_popup => 1,
        },
        ;
};

=head2 PROJECT PAGES

=head3 project

This is the main page for viewing all of the unfinished tasks.

=cut

template 'project' => page {
    { title is 'Projects' }

    # Use list to show all the open projects
    render_region 
        name      => 'task_list',
        path      => 'project/list', 
        arguments => {
            task_type => 'project',
            status    => 'open',
        },
        ;
};

=head3 project/view

This is the editor/viewer for a task.

=cut

template 'project/view' => page {
    my $task = get 'task';

    { title is $task->name }

    p {
        hyperlink
            label => _('Back to Tasks'),
            url   => '/project',
            ;
    };

    my $action = new_action
        class   => 'UpdateTask',
        moniker => 'update-task-'.$task->nickname,
        record  => $task,
        ;

    div { { class is 'project-view inline' }
        form {
            render_action $action, [ qw/ alternate_nickname name / ];

            form_submit
                label  => _('Save'),
                submit => $action,
                ;
        };
    };

    render_region
        name      => 'task-children-'.$task->nickname,
        path      => '/project/list_tasks',
        arguments => {
            parent_id => $task->id,
        },
        ;

    render_region
        name      => 'task-ogs-'.$task->nickname,
        path      => '/project/list_task_logs',
        arguments => {
            task_id => $task->id,
        },
        ;
};

=head2 PROJECT FRAGMENTS

=head3 project/list

This fragment will view a requested set of tasks. Pulls one of several request arguments to determine which tasks to list.

This also renders a new task form at the top.

=over

=item parent_id

If set, only tasks that have this parent ID will be listed.

=item task_type

If set, only tasks that have this task type will be listed. This should be one of C<project>, C<group>, C<action>.

=item status

If set, only tasks that have this status will be listed. This should be one of C<open>, C<done>, C<nix>. Actually, if you choose C<open>, tasks that are C<done> but have a completed timestamp within the last hour will also be shown.

=back

=cut

template 'project/list' => sub {
    div { { class is 'top-spacer' }
        render_region
            name => 'new_task',
            path => 'project/new_task',
            ;
    };

    form {
        render_region
            name => 'list_tasks',
            path => 'project/list_tasks',
            arguments => {
                parent_id => get('parent_id'),
                task_type => get('task_type'),
                status    => get('status'),
            },
            ;
    };
};

=head3 project/new_task

Show a very simple new task form.

=cut

template 'project/new_task' => sub {
    my $action = new_action
        class   => 'CreateTask',
        moniker => 'new_task',
        ;

    div { { class is 'new_task' }
        form {
            p { _('New task:') };
            render_action $action, [ qw/ name / ];
            form_submit
                label   => _('Create'),
                onclick => {
                    submit  => $action,
                    refresh => Jifty->web->current_region->parent,
                },
                ;
        };
    };
};

=head3 project/list_tasks

List all the tasks requested. This template uses the same arguments as L</project/list>.

=cut

template 'project/list_tasks' => sub {
    my $parent_id = get 'parent_id';
    my $task_type = get 'task_type';
    my $status    = get 'status';

    # Load all the tasks
    my $tasks = Qublog::Model::TaskCollection->new;
    $tasks->unlimit;

    # Limit by parent ID, if requested
    $tasks->limit(
        column => 'parent',
        value  => $parent_id,
        entry_aggregator => 'AND',
    ) if $parent_id;

    # Limit by task type, if requested
    $tasks->limit(
        column => 'task_type',
        value  => $task_type,
        entry_aggregator => 'AND',
    ) if $task_type;

    # Limit by open and or completed within the last hour tasks
    if ($status eq 'open') {
        $tasks->open_paren('status');

        $tasks->open_paren('status');

        # Is the completed timestamp within the last hour?
        $tasks->limit(
            column    => 'completed_on',
            operator  => '>=',
            value     => Jifty::DateTime->now->subtract( hours => 1 )->format_cldr('YYYY-MM-dd HH:mm:ss'),
            subclause => 'status',
            entry_aggreagator => 'AND',
        );
        
        # Is the status done?
        $tasks->limit(
            column    => 'status',
            value     => 'done',
            subclause => 'status',
            entry_aggregator => 'AND',
        );

        $tasks->close_paren('status');

        # Otherwise, is the status open
        $tasks->limit(
            column    => 'status',
            value     => $status,
            subclause => 'status',
            entry_aggregator => 'OR',
        );

        $tasks->close_paren('status');
    }

    # Otherwise, does the status match?
    elsif ($status) {
        $tasks->limit(
            column => 'status',
            value  => $status,
            entry_aggregator => 'AND',
        );
    }

    # Show the tasks if there are any
    if ($tasks->count > 0) {
        while (my $task = $tasks->next) {
            show './view_task', { task => $task, recursive => 1 };
        }
    }
    
    # Show an empty message if none
    else {
        p { { class is 'empty' }
            if ($status and $task_type) {
                outs _('No %1 %2 found.', $status, PL($task_type)) 
            }
            elsif ($status) {
                outs _('No %1 tasks found.', $status);
            }
            elsif ($task_type) {
                outs _('No %1 found.', PL($task_type));
            }
            else {
                outs _('No tasks found.');
            }
        };
    }
};

=head3 project/list_task_logs

Show the task log for a task.

=cut

template 'project/list_task_logs' => sub {
    my $task_id = get 'task_id';

    my $task = Qublog::Model::Task->new;
    $task->load( $task_id );

    div { { class is 'comment list' }
        my $comments = $task->comments;
        while (my $comment = $comments->next) {
            show '/journal/view_comment', $comment;
        }
    };
};

=head2 PROJECT PRIVATE TEMPLATES

=head3 project/view_task TASK

Shows a task for viewing.

=cut

private template 'project/view_task' => sub {
    my ($self, $args) = @_;

    my $task = $args->{task};

    # Show the droppable for top level projects if this is a project
    div { { class is 'top_level' } _('Top-level Project') }
        if $task->task_type eq 'project';

    # Show the task
    div { 
        { 
            id is 'task-'.$task->id, 
            class is 'task '.$task->task_type.' '.$task->status
                            .($task->is_none_project ? ' none-project' : '')
        }

        # Show actions unless this is "none", which shouldn't be edited
        if (not $task->is_none_project) {
            my $action = new_action
                class   => 'UpdateTask',
                moniker => 'update-task-'.$task->id,
                record  => $task,
                ;

            Jifty->web->form->register_action($action);

            div { { class is 'actions' }

                # Helper sub for creating the actions
                my $status_update = sub {
                    my ($label, $status, $confirm) = @_;
                    if ($task->status ne $status) {
                        hyperlink
                            label   => $label,
                            tooltip => _("%1 this task", $label),
                            class   => "icon-only $status",
                            as_link => 1,
                            onclick => {
                                refresh      => Jifty->web->current_region->parent,
                                confirm      => $confirm,
                                submit       => {
                                    action    => $action,
                                    arguments => {
                                        status => $status,
                                    },
                                },
                            },
                            ;

                        outs ' ';
                    }
                };

                $status_update->(_('Nix'),      'nix', 'Are you sure?');
                $status_update->(_('Complete'), 'done');
                $status_update->(_('Re-open'),  'open');

                # TODO This should do something...
                hyperlink(
                    label   => _('Edit'),
                    tooltip => _('Edit this task'),
                    class   => 'icon-only edit',
                    url     => '/project/edit/'.$task->nickname
                );
            }
        };

        # This helper sub renders the "subject" header
        my $subject = sub {
            span { { class is 'nickname' } '#'.$task->nickname.':' };
            outs ' ';
            span { { class is 'name' } outs_raw htmlify($task->name) };
        };

        # Use a different header for each task type
        if ($task->task_type eq 'project') {
            h2 { { id is $task->nickname, class is 'subject' } $subject->() };
        }
        elsif ($task->task_type eq 'group') {
            h3 { { id is $task->nickname, class is 'subject' } $subject->() };
        }
        else {
            h4 { { id is $task->nickname, class is 'subject' } $subject->() };
        }

        # If this can have children (group or project) try to show them
        if ($args->{recursive} and $task->task_type ne 'action') {
            render_region
                name => 'children_of_'.$task->id,
                path => 'project/list_tasks',
                arguments => {
                    parent_id => $task->id,
                    status    => 'open',
                    task_type => '',
                },
                ;
        }
    };
};

=head3 project/project_summary

Shows a quick summary of the tasks that belong to a project or group.

=cut

private template 'project/project_summary' => sub {
    my ($self, $project) = @_;

    my $tasks = $project->children;
    $tasks->limit( column => 'status', value => 'open' );

    ul { { class is 'project-summary' }
        while (my $task = $tasks->next) {
            li { { id is 'summary-'.$task->nickname, class is 'subject' }
                span { { class is 'nickname' }
                    '#'.$task->nickname.':'
                };
                outs ' ';
                span { { class is 'name' }
                    outs_raw htmlify($task->name);
                };

                if ($task->task_type ne 'action') {
                    show './project_summary', $task;
                }
            };
        }
    };
};

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
