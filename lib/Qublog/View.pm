use strict;
use warnings;

package Qublog::View;
use Jifty::View::Declare -base;

use Qublog::Web;
use Qublog::Web::Format;
use Lingua::EN::Inflect qw/ PL /;
use List::Util qw/ max /;
use Scalar::Util qw/ reftype /;
use Storable qw/ dclone /;

=head1 NAME

Qublog::View - view templates for Qublog

=head1 METHODS

I have built some helper methods for use with Qublog.

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

=head1 journal_items RECORD

Given a loaded L<Qublog::Model::JournalDay>, L<Qublog::Model::JournalEntry>, L<Qublog::Model::JournalTimer>, or L<Qublog::Model::Comment>, this will build a list of hash references ready to be used as arguments to the L<journal/item> template.

=cut

sub _journal_items_day {
    my ($self, $items) = @_;

    my $timers = Qublog::Model::JournalTimerCollection->new;
    my $entry_alias = $timers->join(
        column1 => 'journal_entry',
        table2  => Qublog::Model::JournalEntry->table,
        column2 => 'id',
    );
    $timers->limit(
        alias  => $entry_alias,
        column => 'journal_day',
        value  => $self->id,
    );
    $timers->limit(
        alias  => $entry_alias,
        column => 'owner',
        value  => Jifty->web->current_user->id,
    );
    $timers->order_by({ column => 'start_time' });

    while (my $timer = $timers->next) {
        journal_items($timer, $items);
    }

    my $comments = $self->comments;
    while (my $comment = $comments->next) {
        journal_items($comment, $items);
    }
}

sub _journal_items_entry {
    my ($self, $items) = @_;

    # TODO Add items for the entry itself?

    my $timers = $self->timers;
    $timers->order_by({ column => 'start_time' });

    while (my $timer = $timers->next) {
        journal_items($timer, $items);
    }
}

sub _journal_items_timer {
    my ($self, $items) = @_;
    my $journal_entry = $self->journal_entry;

    my $collapse_start;
    for my $item_id (keys %$items) {
        next unless $item_id =~ /JournalTimer-\d+-stop/;
        if ($items->{$item_id}{timestamp} == $self->start_time) {
            $collapse_start = $item_id;
            last;
        }
    }

    my $id = 'JournalTimer-'.$self->id.'-';

    if ($collapse_start) {
        $items->{$collapse_start}{content}{attributes}{title}
            .= _('(Start %1)', $journal_entry->name);
        $items->{$collapse_start}{row}{class} .= ' start';
    }
    else {
        $items->{$id.'start'} = {
            id             => $self->id,
            order_priority => $self->start_time->epoch * 10 + 1,

            row       => {
                class => 'timer start',
            },
            timestamp => $self->start_time,
            content   => {
                content => _('Started %1', $journal_entry->name),
                icon    => 'a-begin o-timer',
                format  => [ 'p' ],
            },
            info3     => '&nbsp;',
            links     => [
                {
                    label   => _('Change'),
                    class   => 'icon v-edit o-timer',
                    tooltip => _('Set the start time for this timer span.'),
                    onclick => {
                        open_popup   => 1,
                        replace_with => 'journal/popup/change_start_stop',
                        arguments    => {
                            entry_id => $journal_entry->id,
                            which    => 'start',
                            timer_id => $self->id,
                        },
                    },
                },
            ],
        };
    }

    # Make some handy calculations
    my $js_time_format = 'eee MMM dd HH:mm:ss zzz yyy';
    my $start_time = $self->start_time->format_cldr($js_time_format);
    my $load_time  = Jifty::DateTime->now->format_cldr($js_time_format);
    my $total_duration = $journal_entry->hours;

    my @stop_links = ({
        label   => _('Edit Info'),
        class   => 'icon v-edit o-entry',
        tooltip => _('Edit the journal information for this entry.'),
        onclick => {
            open_popup   => 1,
            replace_with => 'journal/popup/edit_entry',
            arguments    => {
                entry_id => $journal_entry->id,
                timer_id => $self->id,
            },
        },
    });

    if ($self->is_stopped) {
        push @stop_links, {
            label   => _('Change'),
            class   => 'icon v-edit a-end o-timer',
            tooltip => _('Set the stop time for this timer span.'),
            onclick => {
                open_popup   => 1,
                replace_with => 'journal/popup/change_start_stop',
                arguments    => {
                    entry_id => $journal_entry->id,
                    which    => 'stop',
                    timer_id => $self->id,
                },
            },
        };

        if ($journal_entry->is_stopped) {
            push @stop_links, {
                label   => _('Restart'),
                class   => 'icon v-start o-timer',
                tooltip => _('Start a new timer for this entry.'),
                as_link => 1,
                onclick => {
                    refresh => 'journal_list',
                    submit  => new_action(
                        class  => 'StartTimer',
                        record => $journal_entry,
                    ),
                },
            };
        }
    }
    else {
        push @stop_links, {
            label   => _('Stop'),
            class   => 'icon v-stop o-timer',
            tooltip => _('Stop this timer.'),
            as_link => 1,
            onclick => {
                refresh => 'journal_list',
                submit  => new_action(
                    class  => 'StopTimer',
                    record => $journal_entry,
                ),
            },
        };
    }

    push @stop_links, {
        label   => _('List Actions'),
        class   => 'icon v-view a-list o-task',
        tooltip => _('Show the list of tasks for this project.'),
        onclick => {
            open_popup   => 1,
            replace_with => 'journal/popup/show_tasks',
            arguments    => {
                entry_id => $journal_entry->id,
            },
        },
    } if $journal_entry->project->id;

    $items->{$id.'stop'} = {
        id             => $self->id,
        order_priority => $self->start_time->epoch * 10 + 9,

        row       => {
            class => 'timer stop hours-summary'
               .' '. ($journal_entry->is_running ? 'entry-running' 
                                                 : 'entry-stopped')
               .' '. ($self->is_running    ? 'span-running'
                                                 : 'span-stopped'),
            attributes => {
                start_time       => $start_time,
                load_time        => $load_time,
                total_duration   => $total_duration,
                elapsed_duration => $self->hours,
            },
        },
        timestamp => $self->stop_time || Jifty::DateTime->now,
        content   => {
            content => $journal_entry->name,
            icon    => 'a-end o-timer',
            format  => [ 'p' ],
        },
        info1     => {
            content => scalar span {
                # Output the duration elapsed for the current timer
                span { { class is 'number' } 
                    sprintf '%.2f', $self->hours 
                };
                span { { class is 'unit' } _('hours elapsed') };
            },
            format => [
                {
                    format  => 'p',
                    options => {
                        class => 'duration elapsed',
                    },
                },
            ],
        },
        info2     => {
            content => scalar span {
                # Output the total duration for the current entry
                span { { class is 'number' } 
                    sprintf '%.2f', $self->journal_entry->hours 
                };
                span { { class is 'unit' } _('hours total') };
            },
            format => [
                {
                    format  => 'p',
                    options => {
                        class => 'duration total',
                    },
                },
            ],
        },
        links     => \@stop_links,
    };
}

sub _journal_items_comment {
    my ($self, $items) = @_;

    my $order_priority = eval {
          $self->journal_timer->id ? $self->journal_timer->start_time->epoch
        :                            $self->created_on;
    } || 0;
    $order_priority *= 10;
    $order_priority += 5;

    # HACK There should be a cleaner way
    my $processed_name_cache = $self->processed_name_cache;
    unless ($processed_name_cache) {
        $processed_name_cache = Qublog::Web::htmlify($self->name);
        $self->set_processed_name_cache($processed_name_cache);
    }

    my $comment_item = $items->{'Comment-'.$self->id} = {
        id             => $self->id,
        order_priority => $order_priority,

        row       => {
            class => 
                ($self->journal_timer->id ? 'timer-comment' : 'free-comment'),
        },

        timestamp => $self->created_on,
        content   => {
            content => $processed_name_cache,
            format  => [ 'div' ],
        },

        links     => [
            {
                label   => _('Edit'),
                class   => 'icon v-edit o-comment',
                onclick => {
                    open_popup => 1,
                    replace_with => 'journal/popup/edit_comment',
                    arguments    => {
                        comment_id => $self->id,
                    },
                },
            },
            {
                label   => _('Remove'),
                class   => 'icon v-delete o-comment',
                as_link => 1,
                onclick => {
                    refresh => 'journal_list',
                    confirm => _('Are you sure? This cannot be undone.'),
                    submit  =>  new_action(
                        class  => 'DeleteComment',
                        record => $self,
                    ),
                },
            },
        ],
    };
}

sub _journal_items_task {
    my ($self, $items) = @_;
    
    my $comments = $self->comments;
    while (my $comment = $comments->next) {
        journal_items($comment, $items);
    }
}

sub _journal_items_tag {
    my ($self, $items) = @_;
    
    my $comments = $self->comments;
    while (my $comment = $comments->next) {
        journal_items($comment, $items);
    }

    my $tasks = $self->tasks;
    while (my $task = $tasks->next) {
        journal_items($task, $items);
    }

    my $journal_entries = $self->journal_entries;
    while (my $journal_entry = $journal_entries->next) {
        journal_items($journal_entry, $items);
    }
}

my %JOURNAL_ITEMS_HANDLER = (
    Comment      => \&_journal_items_comment,
    JournalDay   => \&_journal_items_day,
    JournalEntry => \&_journal_items_entry,
    JournalTimer => \&_journal_items_timer,
    Tag          => \&_journal_items_tag,
    Task         => \&_journal_items_task,
);

sub journal_items {
    my ($record, $items) = @_;
    $items ||= {};

    for my $model (keys %JOURNAL_ITEMS_HANDLER) {
        if ($record->isa("Qublog::Model::$model")) {
            my $journal_items = $JOURNAL_ITEMS_HANDLER{$model};
            $journal_items->($record, $items);
            last;
        }
    }
    
    return $items;
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

    div { { class is 'journal' }
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

    my $hours_left = max(0, 8 - $total_hours);

    my $quitting_time;
    my $is_today = $day->is_today;
    if ($is_today and $hours_left > 0) {
        my $planned_duration = DateTime::Duration->new( hours => $hours_left );

        $quitting_time = Jifty::DateTime->now + $planned_duration;
    }

    # Make some handy calculations
    my $js_time_format = 'eee MMM dd HH:mm:ss zzz yyy';
    my $load_time = Jifty::DateTime->now->format_cldr($js_time_format);

    show './item', {
        row     => {
            class      => 'day-summary',
            attributes => {
                load_time      => $load_time,
                total_duration => $total_hours,
            },
        },
        content => {
            content => scalar span {
                span { { class is 'unit' } _('Quitting time ') };
                span { { class is 'time' } 
                    format_time $quitting_time;
                };
            },
            icon    => 'a-quit o-time',
            format  => [ 
                {
                    format  =>  'p',
                    options => {
                        class => 'quit',
                    },
                },
            ],
        },
        info1 => {
            content => scalar span {
                span { { class is 'number' } sprintf '%.2f', $total_hours };
                span { { class is 'unit' } _('hours so far') };
            },
            format  => [
                {
                    format  => 'p',
                    options => {
                        class => 'total',
                    },
                },
            ],
        },
        info2 => {
            content => scalar span {
                span { { class is 'number' } sprintf '%.2f', $hours_left };
                span { { class is 'unit' } _('hours to go') };
            },
            format => [
                {
                    format  => 'p',
                    options => {
                        class => 'remaining',
                    },
                },
            ],
        },
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
            $go_to_date->argument_value( date => $day->datestamp );
            render_action $go_to_date;
            form_submit
                label  => _('Go'),
                class  => 'icon v-view o-day',
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

    show './items', $day;
};

=head3 journal/new_comment_entry

Creates new comments, tasks, timers, and entries as determined by the user's input.

=cut

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
                class   => 'new_comment_entry_submit '
                         . 'icon v-'.(lc $post_label).' o-thingy',
                label   => $post_label,
                onclick => {
                    submit  => $action,
                    refresh => Jifty->web->current_region->parent,
                },
                ;
        };
    };

    show '/help/journal/new_comment_entry';
};

=head2 JOURNAL PRIVATE TEMPLATES

=head3 journal/items OBJECT

This is a sub-template used to display all the journal items associated with the given object.

=cut

private template 'journal/items' => sub {
    my ($self, $object) = @_;

    my $items = journal_items($object);
    for my $item (sort { 
                $b->{timestamp}      <=> $a->{timestamp}      ||
                $b->{order_priority} <=> $a->{order_priority} ||
                $b->{id}             <=> $a->{id}
            } values %$items) {
        show './item', $item;
    }
};

=head3 journal/item OPTIONS

This is a sub-template used to render most of the information in the comment page. This is the template that provides the markup to induce the nice tabular display of information on this page.

As of this writing, this defines six different boxes that can be included on a line. The boxes are:

=over

=item *

B<Timestamp.> This is a 90 pixel wide column at the start of each item line,usually containing a time stamp.

=item *

B<Content.> This is a flexible width column containing the main guts of the information related to the item.

=item *

B<Info1.> This is an informational line that is 150 pixels wide that goes after the Content. This is used to contain a small amount of summary information about the item.

=item *

B<Info2.> This is an informational line that is 150 pixels wide at the very end of the line after the Info1 box. This is used to contain a small amount of summary information about the item.

=item *

B<Info3.> This is an informational line that is 300 pixels wide at the very end of the line after the Content. If used with either or both of Info1 and Info2, this will appear immediately below these. If neither of those are present, this will slide upward to fill the space they normally hold.

=item *

B<Links.> This is a line immediately below the Content and is used to show a list of action links that can be taken related to the item.

=item *

B<Row.> This is a special box that wraps all the others.

=back

In addition to these, there is a special action region that can be used to place forms and other information during the client lifetime of the item.

Each of the above translates into an option: timestamp, content, info1, info2, info3, links, and row. Each option takes either a value that describes the content to be placed within the box or a hash reference containing a complete set of options used to modify that box. The exception is that for row, it only makes sense to give the hash since it doesn't take the C<content> option.

Here is the complete list of options available for each box.

=over

=item content

This is the text or HTML to place within the box. It will be formatted according to the C<format> option. The C<row> box does not take this option.

=item icon

This is the icon class for the box. If set to an available icon, this will insert that icon at the front of the box before the text. If this is set to C<undef>, no icon will be shown. Some boxes have this set to something other than C<undef> by default:

=over

=item timestamp

The default is "time".

=item content

The default is "comment".

=back

The C<row> box does not take this option.

=item id

This is an HTML ID attribute to give to the box.

=item class

This is an additional CSS class for to assign to the box.

=item attributes

This is a hash of additional attributes to assign to the div surrounding the content.

=item format

This is a scalar or array of scalars describing the formats to apply to the C<content> placed inside the box. See L<Qublog::Web::Format> for details on what each of these mean.

Each box has a set of defaults:

=over

=item timestamp

The default is C<[ "time" ]>.

=item content

The default is C<[ "htmlify" ]>.

=item info1, info2, info3

The default is C<[ "p" ]>.

=item links

The default is:

  [ { format => "popup", options => { popup_id => ... } }, "links" ]

=back

The C<row> box does not take this option.

=back

=cut

private template 'journal/item/box' => sub {
    my ($self, $options) = @_;

    my $class  = $options->{class} || '';
       $class .= ' icon ' . $options->{icon} if $options->{icon};

    div { { class is $options->{_name} }
        div {
            attr {
                %{ $options->{attributes} || {} },
                id    => $options->{id},
                class => $class,
            };

            outs_raw apply_format($options->{content}, $options->{format});
        };
    };
};

my %defaults = (
    timestamp => {
        _name  => 'timestamp',
        format => [ 'time' ],
        icon   => 'o-time',
    },
    content   => {
        _name  => 'item-content',
        format => [ 'htmlify' ],
        icon   => 'o-comment',
    },
    info1     => {
        _name  => 'info1',
        format => [ 'p' ],
    },
    info2     => {
        _name  => 'info2',
        format => [ 'p' ],
    },
    info3     => {
        _name  => 'info3',
        format => [ 'p' ],
    },
    links     => {
        _name  => 'links',
        format => [ 
            {
                format  => 'popup',
            },
            'links',
        ],
    },
);

private template 'journal/item' => sub {
    my ($self, $options) = @_;

    div {
        my $row_id       = $options->{row}{id} || 'row_'.Jifty->web->serial;
        my $popup_region = $row_id . '_actions';
        my $popup_id     = Jifty->web->current_region->qualified_name
                         . '-' . $popup_region;

        attr {
            %{ $options->{row}{attributes} || {} },
            id    => $row_id,
            class => 'item ' . ($options->{row}{class} || ''),
        };

        for my $box (qw( links content timestamp info1 info2 info3 )) {
            my %box_options = ( 
                %{ dclone($defaults{$box}) },
                (ref $options->{$box} eq 'HASH' ? %{ $options->{$box} || {} }
                :                           ( content => $options->{$box} ) )
            );

            if ($box_options{content}) {
                if ($box eq 'content' or $box eq 'links') {
                    if ($box eq 'links') {
                        if (ref $box_options{format} eq 'ARRAY'
                                and ref $box_options{format}[0] eq 'HASH'
                                and $box_options{format}[0]{format} eq 'popup',
                                and not defined $box_options{format}[0]{options}{popup_id}) {

                            $box_options{format}[0]{options}{popup_id} = $popup_id;
                        }
                    }

                    div { { class is 'item-wrapper' }
                        show './item/box', \%box_options;
                    };
                }
                else {
                    show './item/box', \%box_options;
                }
            }
        }

        render_region
            name => $popup_region,
            path => '/__jifty/empty',
            ;
    };
}; 

=head2 JOURNAL POPUPS

=head3 journal/popup/edit_comment

This shows a popup editor for a journal comment's information.

=cut

template 'journal/popup/edit_comment' => sub {
    my $comment = get 'comment';

    my $action = new_action
        class  => 'UpdateComment',
        record => $comment,
        ;

    render_param $action, 'created_on', 
        default_value => format_time($comment->created_on);
    render_param $action, 'name';

    popup_submit
        label   => _("Save"),
        class   => 'icon v-save a-existing o-comment',
        onclick => [ 
            {
                submit      => $action,
                close_popup => 1,
            },
            {
                refresh     => 'journal_list',
            },
        ],
        ;

    popup_submit
        label   => _('Cancel'),
        class   => 'icon v-cancel',
        onclick => [
            {
                close_popup => 1,
            },
            {
                refresh     => 'journal_list',
            },
        ],
        ;
};

=head3 journal/popup/edit_entry

This shows a popup editor for a journal entry's information.

=cut

template 'journal/popup/edit_entry' => sub {
    my $entry = get 'entry';

    my $action = new_action
        class  => 'UpdateJournalEntry',
        record => $entry,
        ;

    render_action $action; 

    popup_submit
        label   => _("Save"),
        class   => 'icon v-save a-existing o-entry',
        onclick => [ 
            {
                submit      => $action,
                close_popup => 1,
            },
            {
                refresh     => 'journal_list',
            },
        ],
        ;

    popup_submit
        label   => _('Cancel'),
        class   => 'icon v-cancel',
        onclick => [
            {
                close_popup => 1,
            },
            {
                refresh     => 'journal_list',
            },
        ],
        ;
};

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
        class   => 'icon v-save a-existing o-time',
        onclick => [ 
            {
                submit      => $action,
                close_popup => 1,
            },
            {
                refresh     => 'journal_list',
            },
        ],
        ;

    popup_submit
        label   => _('Cancel'),
        class   => 'icon v-cancel',
        onclick => [
            {
                close_popup => 1,
            },
            {
                refresh     => 'journal_list',
            },
        ],
        ;
};

=head3 journal/popup/show_tasks

Shows the tasks for a given journal entry.

=cut

template 'journal/popup/show_tasks' => sub {
    my $entry = get 'entry';
    my $task  = $entry->project;

    if ($task->id) {
        show '/project/project_summary', $task;
    }

    else {
        p { { class is 'none' } _('No project associated with this entry.') };
    }

    popup_submit
        label   => _('Close'),
        class   => 'icon v-collapse',
        onclick => [
            {
                close_popup => 1,
            },
        ],
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
            class => 'icon v-return o-task',
            url   => '/project',
            ;
    };

    my $action = new_action
        class   => 'UpdateTask',
        moniker => 'update-task-'.$task->tag,
        record  => $task,
        ;

    div { { class is 'project-view inline' }
        form {
            render_action $action, [ qw/ tag_name name / ];

            form_submit
                label  => _('Save'),
                class  => 'icon v-save o-comment',
                submit => $action,
                ;
        };
    };

    render_region
        name      => 'task-children-'.$task->tag,
        path      => '/project/list_tasks',
        arguments => {
            parent_id => $task->id,
        },
        ;

    render_region
        name      => 'task-ogs-'.$task->tag,
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
                class   => 'icon v-save a-new o-task',
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
    $tasks->limit(
        column => 'owner',
        value  => Jifty->web->current_user->id,
    );

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
        show '/journal/items', $task;
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
                            class   => "icon only v-$status o-task",
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
                    class   => 'icon only v-edit o-task',
                    url     => '/project/edit/'.$task->tag
                );
            }
        };

        # This helper sub renders the "subject" header
        my $subject = sub {
            span { { class is 'nickname' } '#'.$task->tag.':' };
            outs ' ';
            span { { class is 'name' } outs_raw htmlify($task->name) };
        };

        # Use a different header for each task type
        if ($task->task_type eq 'project') {
            h2 { 
                { 
                    id is $task->tag, 
                    class is 'icon a-project o-task subject' 
                } 
                $subject->() 
            };
        }
        elsif ($task->task_type eq 'group') {
            h3 { 
                { 
                    id is $task->tag, 
                    class is 'icon a-group o-task subject' 
                } 
                $subject->() 
            };
        }
        else {
            h4 { 
                { 
                    id is $task->tag, 
                    class is 'icon a-action o-task subject' 
                } 
                $subject->() 
            };
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
                    show './project_summary', $task;
                }
            };
        }
    };
};

=head2 TAG PAGES

=head3 tag

Shows a summary of tags in the system.

=cut

template 'tag' => page {
    { title is 'Tags' }

    p {
        my $sql = qq{
            SELECT tags.name, comments.created_on
            FROM tags INNER JOIN comment_tags ON (tags.id = comment_tags.tag)
                      INNER JOIN comments ON (comment_tags.comment = comments.id)
            WHERE comments.owner = ?

            UNION

            SELECT tags.name, journal_entries.start_time
            FROM tags INNER JOIN journal_entry_tags ON (tags.id = journal_entry_tags.tag)
                      INNER JOIN journal_entries ON (journal_entry_tags.journal_entry = journal_entries.id)
            WHERE journal_entries.owner = ?

            UNION

            SELECT tags.name, tasks.created_on
            FROM tags INNER JOIN task_tags ON (tags.id = task_tags.tag)
                       INNER JOIN tasks ON (task_tags.task = tasks.id)
            WHERE tasks.owner = ?
        };

        my $sth = Jifty->handle->dbh->prepare($sql);
        $sth->execute( (Jifty->web->current_user->id) x 3 );

        my %tags;
        my $max_total = 1;
        my $min_total = 4_000_000_000;
        my $now = Jifty::DateTime->now;
        while (my ($name, $timestamp) = $sth->fetchrow_array) {
            my $dt     = Jifty::DateTime->new_from_string($timestamp);
            my $months = ($now->epoch - $dt->epoch) / 2592000;
            
            $tags{ $name } += 2.5 / (log(0.25 * $months + 1.5)) - 1;
            
            $max_total = $tags{ $name } if $tags{ $name } > $max_total;
            $min_total = $tags{ $name } if $tags{ $name } < $min_total;
        }
        
        for my $tag_name (keys %tags) {
            my $total = ($tags{ $tag_name } - $min_total) * 3 / ($max_total - $min_total);

            span { 
                { style is "font-size: ".(0.8 + $total)."em" }
                outs ' ';
                hyperlink
                    label => '#' . $tag_name,
                    class => 'icon center-left v-view o-tag',
                    url   => '/tag/view/' . $tag_name,
                    ;
                outs ' ';
            };

        }
    };
};

=head3 tag/view

Used to view the comments, entries, and tasks linked to a particular tag.

=cut

template 'tag/view' => page {
    my $tag = get 'tag';

    { title is '#' . $tag->name }

    p {
        hyperlink
            label => _('Back to Tags'),
            class => 'icon v-return o-tag',
            url   => '/tag',
            ;
    };

    render_region
        name      => 'journal_list',
        path      => '/tag/items',
        arguments => {
            tag_name => $tag->name,
        },
        ;
};

=head2 TAG FRAGMENTS

=head3 tag/items

Show the items associated with a tag.

=cut

template 'tag/items' => sub {
    my $tag = get 'tag';

    div { { class is 'journal' }
        show '/journal/items', $tag;
    };
};

=head2 USER PAGES

=head3 user/register

This is the new user registration page.

=cut

template 'user/register' => page {
    title is _('New User Registration');

    p { 
        outs_raw _(q{
            Before using Qublog, you must register a user account. Please fill
            in the form below and click <strong>Register</strong> when finished.
        });
    };

    form {
        my $register = new_action 'CreateUser';
        render_param $register, 'name';
        render_param $register, 'email';
        render_param $register, 'password';
        render_param $register, 'password_confirm', label => _('Type again');
        form_return
            label  => _('Register'),
            submit => $register,
            to     => '/journal',
            ;
    };
};

=head3 user/login

This is the user login page.

=cut

template 'user/login' => page {
    title is 'Login';

    form {
        my $login = new_action 'Login';
        render_action $login;
        form_return
            label  => _('Login'),
            class  => 'icon v-sign-in',
            submit => $login,
            ;
    };

    p {
        tangent
            url   => '/user/register',
            class => 'icon v-register o-user',
            label => _(q{Don't have an account? Register for one.}),
            ;
    };
};

=head2 HELP

=head3 help/journal/new_comment_entry

On screen help for creating new comments and such.

=cut

template 'help/journal/new_comment_entry' => sub {
    div { 
        { 
            id    is 'inline-help',
            style is 'display:none'
        }

        h3 { { class is 'icon o-help' } 'Quick Reference' };

        div { { id is 'thingy-on', class is 'context' }
            dl {
                dt { '#tag' };        dd { 'Create a task with tagged "#tag" or comment on that task' };
                dt { '#tag: Title' }; dd { 'Start, restart, or comment upon a journal entry linked to #tag' };
            };
        };

        div { { id is 'thingy-comment', class is 'context' }
            dl {
                dt { '#tag' };             dd { 'create or references a tag' };
                dt { '[ ] #tag: title' };  dd { 'create or update a task' };
                dt { '-[ ] #tag: title' }; dd { 'create a subtask' };
                dt { '[x] #tag' };         dd { 'mark a task as complete' };
                dt { '[!] #tag' };         dd { 'cancel a task' };
            };
        };
    };
};

=head2 OTHER SPECIAL BITS

=head3 salutation

Show the salutation up in the corner.

=cut

template 'salutation' => sub {
    div { 
        { id is 'salutation' }

        if (Jifty->web->current_user->id) {
            outs 'Hello, ';
            outs(Jifty->web->current_user->user_object->name);
            outs ' (';
            hyperlink
                url   => '/logout',
                class => 'icon v-sign-out',
                label => _('sign out'),
                ;
            outs ')';
        }

        else {
            outs 'Please ';
            hyperlink 
                url   => '/user/login',
                class => 'icon v-sign-in',
                label => _('sign in'),
                ;
            outs ' or ';
            hyperlink
                url   => '/user/register',
                class => 'icon v-register o-user',
                label => _('register'),
                ;
            outs '.';
        }
    };
};

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
