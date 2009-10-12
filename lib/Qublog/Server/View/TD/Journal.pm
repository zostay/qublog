package Qublog::Server::View::TD::Journal;
use strict;
use warnings;

use Qublog::DateTime2;
use Qublog::Server::View::Common qw( page );
use Qublog::Web;
use Qublog::Web::Format;

use List::MoreUtils qw( none );
use List::Util qw( max );
use Storable qw( dclone );

use Template::Declare::Tags;

template 'journal/index' => sub {
    my ($self, $c) = @_;

    $c->add_style( file => 'journal' );
    $c->add_script( file => 'journal' );

    my $day = $c->stash->{day};
    $c->stash->{title} = 'Journal';
    if (not $day->is_today) {
        $c->stash->{title} .= ' for ';
        $c->stash->{title} .= Qublog::DateTime->format_human_date($day->datestamp);
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
    my $is_today = $day->is_today;
    if ($is_today and $hours_left > 0) {
        my $planned_duration = DateTime::Duration->new( hours => $hours_left );

        $quitting_time = Qublog::DateTime->now + $planned_duration;
    }

    # Make some handy calculations
    my $js_time_format = 'eee MMM dd HH:mm:ss zzz yyy';
    my $load_time = Qublog::DateTime->now->format_cldr($js_time_format);

    show './item', $c, {
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
                    Qublog::DateTime->format_human_time($quitting_time);
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
    show './items', $c, $day;
};

template 'journal/bits/new_comment_entry' => sub {
    my ($self, $c) = @_;
    my $day = $c->stash->{day};

    # Initial button name
    my $post_label = $day->journal_entries->count == 0 ? 'Start' : 'Post';

    # The create entry form
    div { { class is 'new_comment_entry' }
        form { { action is '/compat/thingy/new', method is 'POST' }
            label { attr { for => 'task_entry' } 'On' };
            input {
                type  is 'text',
                class is 'text task_entry',
                name  is 'task_entry',
            };
            textarea {
                class is 'comment',
                name is 'comment',
            };
            div { { class is 'submit' }
                input {
                    type  is 'submit',
                    class is 'submit',
                    name  is 'submit',
                    class is 'new_comment_entry_submit icon v-'.(lc $post_label).' o-thingy',
                    value is $post_label,
                };
            };
        };
    };

    show '/help/journal/new_comment_entry', $c;
};

my @JOURNAL_FORMS = qw(
    edit_comment
);

template 'journal/bits/items' => sub {
    my ($self, $c, $object) = @_;

    my $form;
    my $form_name  = $c->stash->{form};
    my $form_type  = $c->stash->{form_type};
    my $form_place = $c->stash->{form_place};

    if ($form_name and none { $form_name eq $_ } @JOURNAL_FORMS) {
        warn "INVALID FORM NAME $form_name given.\n";
        undef $form_name;
    }
   
    if ($form_name and $form_type and $form_place) {
        $form = {
            content => '/form/'.$form_name,
            format  => [ 'show' ],
        };
    }

    my $items = $object->journal_items($c);
    
    for my $item (sort {
                $b->{timestamp}      <=> $a->{timestamp}      ||
                $b->{order_priority} <=> $a->{order_priority} ||
                $b->{id}             <=> $a->{id}
            } values %$items) {

        if ($form and $item->{name} eq $form_place) {
            if ($form_type eq 'replace') {
                $item->{content} = $form;
            }
            else {
                $item->{drawer}  = $form;
            }
        }

        show './item', $c, $item;
    }
};

template 'journal/bits/item_box' => sub {
    my ($self, $c, $options) = @_;

    my $class  = $options->{class} || '';
       $class .= ' icon ' . $options->{icon} if $options->{icon};

    div { { class is $options->{_name} }
        div {
            attr {
                %{ $options->{attributes} || {} },
                id    => $options->{id},
                class => $class,
            };

            outs_raw apply_format(
                $options->{content}, $options->{format}, $c
            );
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

template 'journal/bits/item' => sub {
    my ($self, $c, $options) = @_;

    div {
        my $row_id       = $options->{row}{id} 
                        || 'row_'.'random-number-here';
        my $popup_region = $row_id . '_actions';
        my $popup_id     = 'some-qualified-name-' . $popup_region;

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
                                and $box_options{format}[0]{format} eq 'popup'
                                and not defined $box_options{format}[0]{options}{popup_id}) {
                            $box_options{format}[0]{options}{popup_id} = $popup_id;
                        }
                    }

                    div { { class is 'item-wrapper' }
                        show './item_box', $c, \%box_options;
                    };
                }
                else {
                    show './item_box', $c, \%box_options;
                }
            }
        }

        # empty region
        div { attr { id => $options->{name}, class => 'item-drawer' }; 

            show './item_box', $c, $options->{drawer} 
                if $options->{drawer};
        };
    };
};

1;
