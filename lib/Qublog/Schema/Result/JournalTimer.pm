package Qublog::Schema::Result::JournalTimer;
use strict;
use warnings;
use base qw( DBIx::Class );

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

1;
