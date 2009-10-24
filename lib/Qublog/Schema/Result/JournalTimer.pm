package Qublog::Schema::Result::JournalTimer;
use Moose;
extends qw( Qublog::Schema::Result );

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
__PACKAGE__->belongs_to( journal_entry => 'Qublog::Schema::Result::JournalEntry' );
__PACKAGE__->has_many( comments => 'Qublog::Schema::Result::Comment', 'journal_timer' );
__PACKAGE__->resultset_class('Qublog::Schema::ResultSet::JournalTimer');

sub as_journal_item {
    my ($self, $c, $items) = @_;
    my $journal_entry = $self->journal_entry;

    my $collapse_start;
    for my $item_id (%$items) {
        next unless $item_id =~ /JournalTimer-\d+-stop/;
        next if $items->{$item_id}{collapse_start};

        if ($items->{$item_id}{timestamp} == $self->start_time) {
            $items->{$item_id}{collapse_start} = $self;
            $collapse_start++;
            last;
        }
    }

    my $id = 'JournalTimer-'.$self->id.'-';

    unless ($collapse_start) {
        my $start_name = $id.'start';
        $items->{$start_name} = {
            id             => $self->id,
            name           => $start_name,
            order_priority => $self->start_time->epoch * 10 + 1,
            timestamp      => $self->start_time,
            record         => $self,
        };
    }

    my $stop_name = $id.'stop';
    $items->{$stop_name} = {
        id             => $self->id,
        name           => $stop_name,
        order_priority => $self->start_time->epoch * 10 + 9,
        timestamp      => $self->stop_time || Qublog::DateTime->now,
        record         => $self,
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
