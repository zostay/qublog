package Qublog::Schema::Result::JournalDay;
use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('journal_days');
__PACKAGE__->add_columns(
    id        => { data_type => 'int' },
    datestamp => { data_type => 'date' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many( journal_entries => 'Qublog::Schema::Result::JournalEntry', 'journal_day' );
__PACKAGE__->has_many( comments => 'Qublog::Schema::Result::Comment', 'journal_day' );
__PACKAGE__->result_set_class('Qublog::Schema::ResultSet::JournalDay');

1;
