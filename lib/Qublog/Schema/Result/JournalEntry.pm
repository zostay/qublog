package Qublog::Schema::Result::JournalEntry;
use Moose;

extends qw( Qublog::Schema::Result );
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
__PACKAGE__->resultset_class('Qublog::Schema::ResultSet::JournalEntry');

sub new {
    my ($class, $args) = @_;

    $args->{start_time} ||= Qublog::DateTime->now;

    return $class->next::method($args);
}

sub as_journal_item {}

sub list_journal_item_resultsets {
    my ($self, $options) = @_;

    return [] unless $options->{user};

    my $timers = $self->journal_timers;
    $timers->search({
        'journal_entry.owner' => $options->{user}->get_object->id,
    }, {
        join     => [ 'journal_entry' ],
        order_by => { -asc => 'start_time' },
        prefetch => 'journal_entry',
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

sub start_timer {
    my ($self, $now) = shift;
    my $schema = $self->result_source->schema;

    my $timer;
    $schema->txn_do(sub {
        my $running_entries 
            = $schema->resultset('JournalEntry')->search_by_running(1);
        $running_entries = $running_entries->search({
            id => { '!=', $self->id },
        });

        $now ||= Qublog::DateTime->now;
        while (my $running_entry = $running_entries->next) {
            $running_entry->stop_timer($now);
        }

        $timer = $schema->resultset('JournalTimer')->create({
            journal_entry => $self,
            start_time    => $now,
        });

        $self->stop_time(undef);
        $self->update;
    });

    return $timer;
}

sub stop_timer {
    my ($self, $now) = shift;
    my $schema = $self->result_source->schema;

    my $timer;
    $schema->txn_do(sub {
        my $timers = $schema->resultset('JournalTimer')->search_by_running(1);

        $now ||= Qublog::DateTime->now;
        while ($timer = $timers->next) {
            $timer->stop_time($now);
            $timer->update;
        }

        $self->stop_time($now);
        $self->update;
    });
}

1;
