package Qublog::Schema::Result::JournalDay;
use Moose;
extends qw( DBIx::Class );

with qw( Qublog::Schema::Role::Itemized );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('journal_days');
__PACKAGE__->add_columns(
    id        => { data_type => 'int' },
    datestamp => { data_type => 'date' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( journal_entries => 'Qublog::Schema::Result::JournalEntry', 'journal_day' );
__PACKAGE__->many_to_many( journal_timers => journal_entries => 'journal_timers' );
__PACKAGE__->has_many( comments => 'Qublog::Schema::Result::Comment', 'journal_day' );
__PACKAGE__->resultset_class('Qublog::Schema::ResultSet::JournalDay');

sub is_today {
    my $self = shift;
    return $self->datestamp->ymd eq Qublog::DateTime->today->ymd;
}

sub as_journal_item {}

sub journal_items {
    my ($self, $c) = @_;

    my $entries = $self->journal_entries;
    $entries->search({
        'journal_entry.owner' => $c->user->id,
    }, {
        join     => [ 'journal_entry' ],
        order_by => { -asc => 'start_time' },
    });

    return [ $entries ];
}

1;
