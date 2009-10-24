package Qublog::Server::View::TD::Journal;
use strict;
use warnings;

use Qublog::DateTime2;
use Qublog::Server::View::Common qw( page );
use Qublog::Web;
use Qublog::Web::Format;

use List::Util qw( max );

use Template::Declare::Tags;

template 'journal/index' => sub {
    my ($self, $c) = @_;

    $c->add_style( file => 'journal' );
    $c->add_script( file => 'journal' );

    my $day = $c->stash->{day};
    $c->stash->{title} = 'Journal';
    if (not $day->is_today($c->today)) {
        $c->stash->{title} .= ' for ';
        $c->stash->{title} .= Qublog::DateTime->format_human_date(
            $day->datestamp, $c->time_zone);
    }

    page {
        div { { class is 'journal' }
            show './bits/summary', $c;
            show './bits/list', $c;
        };
    } $c;
};

template 'journal/bits/summary' => sub {
    my ($self, $c) = @_;
    my $day = $c->stash->{day};

    my $timers = $day->journal_timers;

    my $total_hours = 0;
    while (my $timer = $timers->next) {
        $total_hours += $timer->hours;
    }

    my $hours_left = max(0, 8 - $total_hours);

    my $quitting_time;
    my $is_today = $day->is_today($c->today);
    if ($is_today and $hours_left > 0) {
        my $planned_duration = DateTime::Duration->new( hours => $hours_left );

        $quitting_time = $c->now + $planned_duration;
    }

    # Make some handy calculations
    my $js_time_format = 'eee MMM dd HH:mm:ss zzz yyy';
    my $load_time = $c->now->format_cldr($js_time_format);

    show '/journal_item/item', $c, {
        row => {
            class      => 'day-summary',
            attributes => {
                load_time      => $load_time,
                total_duration => $total_hours,
            },
        },
        content => {
            content => scalar span {
                span { { class is 'unit' } 'Quitting time ' };
                span { { class is 'time' }
                    Qublog::DateTime->format_human_time(
                        $quitting_time, $c->time_zone);
                };
            },
            icon    => 'a-quit o-time',
            format  => [
                {
                    format  => 'p',
                    options => {
                        class => 'quit',
                    },
                },
            ],
        },
        info1 => {
            content => scalar span {
                span { { class is 'number' } sprintf '%.2f', $total_hours };
                span { { class is 'unit' } 'hours so far' };
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
                span { { class is 'unit' } 'hours to go' };
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

template 'journal/bits/list' => sub {
    my ($self, $c) = @_;
    my $day = $c->stash->{day};

    # Show the Go to form
    div { { id is 'goto_date' }
        form { { action is '/journal/goto', method is 'POST' }
            input {
                type is 'hidden',
                name is 'from_page',
                value is $c->request->uri,
            };
            input {
                type is 'text',
                name is 'date',
                value is $day->datestamp->ymd,
            };
            input {
                type is 'submit',
                name is 'submit',
                value is 'Go',
                class is 'icon v-view o-day',
            };
        };
    };

    show './new_comment_entry', $c;
    show '/journal_item/items', $c, $day;
};

template 'journal/bits/new_comment_entry' => sub {
    my ($self, $c) = @_;
    my $day = $c->stash->{day};

    # Initial button name
    my $post_label = $day->journal_entries->count == 0 ? 'Start' : 'Post';

    my $journal_entry = $day->journal_entries->search_by_running(1)->search({}, {
        order_by => { -desc => 'start_time' },
        rows     => 1,
    })->single;
    my $running_name = $journal_entry ? $journal_entry->name : '';

    # The create entry form
    div { { class is 'new_comment_entry' }
        form { { action is '/compat/thingy/new', method is 'POST' }
            label { attr { for => 'task_entry' } 'On' };
            input {
                type  is 'text',
                class is 'text task_entry',
                id is 'new_task_entry',
                name  is 'task_entry',
                value is $running_name,
            };
            textarea {
                class is 'comment',
                id is 'new_comment',
                name is 'comment',
            };
            div { { class is 'submit' }
                input {
                    type  is 'submit',
                    class is 'submit',
                    id    is 'new_comment_entry-submit',
                    name  is 'submit',
                    class is 'new_comment_entry_submit icon v-'.(lc $post_label).' o-thingy',
                    value is $post_label,
                };
            };
        };
    };

    show '/help/journal/new_comment_entry', $c;
};


1;
