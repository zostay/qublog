package Qublog::Server::View::TD::JournalItem;
use strict;
use warnings;

use Qublog::Web;
use Qublog::Web::Format;

use List::MoreUtils qw( none );
use Storable qw( dclone );
use Template::Declare::Tags;

template 'journal_item/item_box' => sub {
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

my @JOURNAL_FORMS = qw(
    change_start_stop
    edit_comment
    edit_entry
    list_actions
);

template 'journal_item/item' => sub {
    my ($self, $c, $options) = @_;

    my $form;
    my $form_name  = $c->stash->{form};
    my $form_type  = $c->stash->{form_type};
    my $form_place = $c->stash->{form_place};

    if ($form_name and none { $form_name eq $_ } @JOURNAL_FORMS) {
        undef $form_name;
    }
   
    if ($form_name and $form_type and $form_place) {
        $form = {
            content => '/form/'.$form_name,
            format  => [ 'show' ],
        };
    }

    if ($form and $options->{name} eq $form_place) {
        if ($form_type eq 'replace') {
            $options->{content} = $form;
        }
        else {
            $options->{drawer}  = $form;
        }
    }

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

template 'journal_item/items' => sub {
    my ($self, $c, $object) = @_;

    my $items = $object->journal_items({
        user => $c->user,
    });
    
    for my $item (sort {
                $b->{timestamp}      <=> $a->{timestamp}      ||
                $b->{order_priority} <=> $a->{order_priority} ||
                $b->{id}             <=> $a->{id}
            } values %$items) {

        show '/journal_item/result/' . $item->{record}->result_source->source_name, 
            $c, $item;
    }
};

template 'journal_item/result/Comment' => sub {
    my ($td, $c, $item) = @_;

    my $self  = $item->{record};
    my $timer = $self->journal_timer;

    # Cache this info because not caching is expensive
    my $processed_name_cache = $self->processed_name_cache;
    unless ($processed_name_cache) {
        $processed_name_cache = Qublog::Web::htmlify($self->name, $c);
        $self->processed_name_cache($processed_name_cache);
        $self->update;
    }

    $item = {
        %$item,

        row => {
            class => (($timer && $timer->id) ? 'timer-comment'
                     :                         'free-comment'),
        },

        content   => {
            content => $self->processed_name_cache,
            format  => [ 'div' ],
        },

        links => [
            {
                label   => 'Edit',
                class   => 'icon v-edit o-comment',
                goto    => $c->request->uri_with({
                    form       => 'edit_comment',
                    form_place => 'Comment-'.$self->id,
                    form_type  => 'replace',
                    comment    => $self->id,
                }),
            },
            {
                label   => 'Remove',
                class   => 'icon v-delete o-comment',
                action  => $c->uri_for('/compat/comment/delete', $self->id, {
                    return_to => $c->request->uri,
                }),
            },
        ],
    };

    show '../item', $c, $item;
};

template 'journal_item/result/JournalTimer' => sub {
    my ($td, $c, $item) = @_;

    if ($item->{name} =~ /-start$/) {
        show './JournalTimer/start', $c, $item;
    }

    else {
        show './JournalTimer/stop', $c, $item;
    }
};

template 'journal_item/result/JournalTimer/start' => sub {
    my ($td, $c, $item) = @_;

    my $self = $item->{record};
    my $journal_entry = $self->journal_entry;

    $item = {
        %$item,

        row => {
            class => 'timer start',
        },
        content => {
            content => sprintf('Started %s', $journal_entry->name),
            icon    => 'a-begin o-timer',
            format  => [ 'p' ],
        },
        info3 => '&nbsp;',
        links => [
            {
                label   => 'Change',
                class   => 'icon v-edit o-timer',
                tooltip => 'See the start time for this timer span.',
                goto    => $c->request->uri_with({
                    form          => 'change_start_stop',
                    form_place    => $item->{name},
                    journal_timer => $self->id,
                    which         => 'start',
                }),
            },
        ],
    };

    show '../../item', $c, $item;
};

template 'journal_item/result/JournalTimer/stop' => sub {
    my ($td, $c, $item) = @_;

    my $self = $item->{record};
    my $journal_entry = $self->journal_entry;

    # Make some handy calculation
    my $start_time = Qublog::DateTime->format_js_datetime($self->start_time);
    my $load_time  = Qublog::DateTime->format_js_datetime($c->now);
    my $total_duration = $journal_entry->hours;

    my @stop_links = ({
        label   => 'Edit Info',
        class   => 'icon v-edit o-entry',
        tooltip => 'Edit the journal information for this entry.',
        goto    => $c->request->uri_with({
            form          => 'edit_entry',
            form_place    => $item->{name},
            journal_entry => $journal_entry->id,
        }),
    });

    if ($self->is_stopped) {
        push @stop_links, {
            label   => 'Change',
            class   => 'icon v-edit a-end o-timer',
            tooltip => 'Set the stop time for this timer span.',
            goto    => $c->request->uri_with({ 
                form          => 'change_start_stop',
                form_place    => $item->{name},
                journal_timer => $self->id,
                which         => 'stop',
            }),
        };

        if ($journal_entry->is_stopped) {
            push @stop_links, {
                label   => 'Restart',
                class   => 'icon v-start o-timer',
                tooltip => 'Start a new timer for this entry.',
                action  => $c->uri_for('/compat/timer/start', $journal_entry->id, {
                    return_to => $c->request->uri,
                }),
            };
        }
    }
    else {
        push @stop_links, {
            label   => 'Stop',
            class   => 'icon v-stop o-timer',
            tooltip => 'Stop this timer.',
            action  => $c->uri_for('/compat/timer/stop', $journal_entry->id, {
                return_to => $c->request->uri,
            }),
        };
    }

    push @stop_links, {
        label   => 'List Actions',
        class   => 'icon v-view a-list o-task',
        tooltip => 'Show the list of tasks for this project.',
        goto    => $c->request->uri_with({ 
            form          => 'list_actions',
            form_place    => $item->{name},
            journal_entry => $journal_entry->id 
        }),
    } if $journal_entry->project;

    $item = {
        %$item,

        row => {
            class => 'timer stop hours-summary'
                .' '. ($journal_entry->is_running ? 'entry-running'
                      :                             'entry-stopped')
                .' '. ($self->is_running          ? 'span-running'
                      :                             'span-stopped'),
            attributes => {
                start_time       => $start_time,
                load_time        => $load_time,
                total_duration   => $total_duration,
                elapsed_duration => $self->hours,
            },
        },
        content => {
            content => $journal_entry->name,
            icon    => 'a-end o-timer',
            format  => [ 'p' ],
        },
        info1 => {
            content => sprintf(qq{
                <span>
                    <span class="number">%.2f</span>
                    <span class="unit">hours elapsed</span>
                </span>
            }, $self->hours),
            format => [
                {
                    format  => 'p',
                    options => {
                        class => 'duration elapsed',
                    },
                },
            ],
        },
        info2 => {
            content => sprintf(qq{
                <span>
                    <span class="number">%.2f</span>
                    <span class="unit">hours total</span>
                </span>
            }, $journal_entry->hours),
            format => [
                {
                    format  => 'p',
                    options => {
                        class => 'duration total',
                    },
                },
            ],
        },
        links => \@stop_links,
    };

    if ($item->{collapse_start}) {
        my $other_timer = delete $item->{collapse_start};
        $item->{content}{attributes}{title}
            .= sprintf '(Start %s)', $other_timer->journal_entry->name;
        $item->{row}{class} .= 'start';
    }

    show '../../item', $c, $item;
};

1;
