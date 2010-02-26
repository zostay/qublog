package Qublog::Server::View::TD::Journal;
use strict;
use warnings;

use Qublog::DateTime;
use Qublog::Server::View::Common qw( page );
use Qublog::Web;
use Qublog::Web::Format;

use List::Util qw( max );

use Template::Declare::Tags;

=head1 NAME

Qublog::Server::View::TD::Journal - templates for the journal

=head1 DESCRIPTION

Qubloggers do most of their stuff here...

=head1 TEMPLATES

=head2 journal/index

Show the journal page.

=cut

template 'journal/index' => sub {
    my ($self, $c) = @_;

    $c->add_style( file => 'journal' );
    $c->add_style( file => 'tasks' );
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

=head2 journal/bits/summary

Show a timer summary at the top. This is pretty specific to my own needs at the
moment. This needs to be more configurable.

=cut

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

=head2 journal/bits/list

Show the Goto Form, the new comment entry form, and the list of journal items
for today.

=cut

template 'journal/bits/list' => sub {
    my ($self, $c) = @_;
    my $day = $c->stash->{day};

    # Show the Go to form
    div { { id is 'goto_date' }
        form { { action is '/journal/goto', method is 'POST' }
            my $action = $c->action_form( server => 'GotoJournalDate', {
                date => $day->datestamp,
            });
            $action->globals->{from_page} = $c->request->uri;
            $action->setup_and_render(
                moniker => 'journal-goto',
            );

            $action->render_control(button => {
                name  => 'submit',
                label => 'Go',
                class => 'icon v-view o-day',
            });
        };
    };

    show './new_comment_entry', $c;
    show '/journal_item/items', $c, $day;
};

=head2 journal/bits/new_comment_entry

Show the the form for adding new items to the journal.

=cut

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
        form { { method is 'POST', action is '/api/model/thingy/create/TODO' }
            my $action = $c->action_form(schema => 'Thingy::Create' => {
                title => $running_name,
            });

            # TODO Something better than "TODO" goes' here...
            $action->setup_and_render(
                moniker => 'TODO',
                globals => {
                    return_to => $c->request->uri,
                    origin    => $c->request->uri,
                },
            );

            div { { class is 'submit' }
                $action->render_control(button => {
                    name  => 'new_comment_entry-submit',
                    label => $post_label,
                });
            };
        };
    };

    show '/help/journal/new_comment_entry', $c;
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
