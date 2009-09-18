package Qublog::Schema::Result::JournalEntry;
use Moose;

extends qw( DBIx::Class );
with qw( Qublog::Schema::Role::Itemized );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('journal_entries');
__PACKAGE__->add_columns(
    id           => { data_type => 'int' },
    journal_day  => { data_type => 'int' },
    name         => { data_type => 'text' },
    start_time   => { data_type => 'datetime', timezone => 'UTC' },
    stop_time    => { data_type => 'datetime', timezone => 'UTC' },
    primary_link => { data_type => 'text' },
    project      => { data_type => 'int' },
    owner        => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( journal_day => 'Qublog::Schema::Result::JournalDay' );
__PACKAGE__->belongs_to( project => 'Qublog::Schema::Result::Task' );
__PACKAGE__->belongs_to( owner => 'Qublog::Schema::Result::User' );
__PACKAGE__->has_many( journal_timers => 'Qublog::Schema::Result::JournalTimer', 'journal_entry' );
__PACKAGE__->has_many( journal_entry_tags => 'Qublog::Schema::Result::JournalEntryTag', 'journal_entry' );
__PACKAGE__->many_to_many( comments => journal_timer => 'comments' );
__PACKAGE__->many_to_many( tags => journal_entry_tags => 'tag' );

sub as_journal_item {}

sub list_journal_item_resultsets {
    my ($self, $c) = @_;

    return [] unless $c->user_exists;

    my $timers = $self->journal_timers;
    $timers->search({
        'journal_entry.owner' => $c->user->get_object->id,
    }, {
        join     => [ 'journal_entry' ],
        order_by => { -asc => 'start_time' },
    });

    return [ $timers ];
}

sub hours {
    my ($self, %args) = @_;

    my $hours = 0;
    my $timers = $self->journal_timers;
    $timers = $timers->search_by_running(0) if $args{stopped_only};
    while (my $timer = $timers->next) {
        $hours += $timer->hours;
    }
    return $hours;
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
