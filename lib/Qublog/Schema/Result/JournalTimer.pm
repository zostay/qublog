package Qublog::Schema::Result::JournalTimer;
use Moose;
extends qw( DBIx::Class );

with qw( Qublog::Schema::Role::Itemized );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('journal_timers');
__PACKAGE__->add_columns(
    id            => { data_type => 'int' },
    journal_entry => { data_type => 'int' },
    start_time    => { data_type => 'datetime', timezone => 'UTC' },
    stop_time     => { data_type => 'datetime', timezone => 'UTC' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( journal_entry => 'Qublog::Schema::Result::JournalEntry', 'id' );
__PACKAGE__->has_many( comments => 'Qublog::Schema::Result::Comment', 'journal_timer' );
__PACKAGE__->resultset_class('Qublog::Schema::ResultSet::JournalTimer');

sub as_journal_item {
    my ($self, $c, $items) = @_;
    my $journal_entry = $self->journal_entry;

    my $collapse_start;
    for my $item_id (%$items) {
        next unless $item_id =~ /JournalTimer-\d+-stop/;
        if ($items->{$item_id}{timestamp} == $self->start_time) {
            $collapse_start = $item_id;
            last;
        }
    }

    my $id = 'JournalTimer-'.$self->id.'-';

    if ($collapse_start) {
        $items->{$collapse_start}{content}{attributes}{title}
            .= sprintf '(Start %s)', $journal_entry->name;
        $items->{$collapse_start}{row}{class} .= ' start';
    }
    else {
        $items->{$id.'start'} = {
            id             => $self->id,
            order_priority => $self->start_time->epoch * 10 + 1,

            row => {
                class => 'timer start',
            },
            timestamp => $self->start_time,
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

    # Make some handy calculation
    my $start_time = Qublog::DateTime->format_js_datetime($self->start_time);
    my $load_time  = Qublog::DateTime->format_js_datetime(Qublog::DateTime->now);
    my $total_duration = $journal_entry->hours;

    my @stop_links = ({
        label   => 'Edit Info',
        class   => 'icon v-edit o-entry',
        tooltip => 'Edit the journal information for this entry.',
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
            label   => 'Change',
            class   => 'icon v-edit a-end o-timer',
            tooltip => 'Set the stop time for this timer span.',
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
                label   => 'Restart',
                class   => 'icon v-start o-timer',
                tooltip => 'Start a new timer for this entry.',
                as_link => 1,
                onclick => {
                    refresh => 'journal_list',
#                    submit  => new_action(
#                        class  => 'StartTimer',
#                        record => $journal_entry,
#                    ),
                },
            };
        }
    }
    else {
        push @stop_links, {
            label   => 'Stop',
            class   => 'icon v-stop o-timer',
            tooltip => 'Stop this timer.',
            as_link => 1,
            onclick => {
                refresh => 'journal_list',
#                    submit  => new_action(
#                        class  => 'StopTimer',
#                        record => $journal_entry,
#                    ),
            },
        };
    }

    push @stop_links, {
        label   => 'List Actions',
        class   => 'icon v-view a-list o-task',
        tooltip => 'Show the list of tasks for this project.',
        onclick => {
            open_popup   => 1,
            replace_with => 'journal/popup/show_tasks',
            arguments    => {
                entry_id => $journal_entry->id,
            },
        },
    } if $journal_entry->project;

    $items->{$id.'stop'} = {
        id             => $self->id,
        order_priority => $self->start_time->epoch * 10 + 9,

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
        timestamp => $self->stop_time || Qublog::DateTime->now,
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
}

sub list_journal_item_resultsets {
    my ($self, $c) = @_;

    return [] unless $c->user_exists;

    my $comments = $self->comments;
    $comments->search({
        'owner' => $c->user->get_object->id,
    }, {
        order_by => { -asc => 'created_on' },
    });

    return [ $comments ];
}

sub hours {
    my ($self, %args) = @_;

    return 0 if $args{stopped_only} and $self->is_running;

    my $start_time = $self->start_time;
    my $stop_time  = $self->stop_time || Qublog::DateTime->now;

    my $duration = $stop_time - $start_time;
    return $duration->delta_months  * 720 # assume, 30 day months... craziness
         + $duration->delta_days    * 24  # and 24 hour days
         + $duration->delta_minutes / 60
         + $duration->delta_seconds / 3600
         ;
}

sub is_running {
    my $self = shift;
    return not defined $self->stop_time;
}

sub is_stopped {
    my $self = shift;
    return defined $self->stop_time;
}

1;