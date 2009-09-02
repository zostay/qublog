package Qublog::Schema::Result::JournalEntry;
use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('journal_entries');
__PACKAGE__->add_columns(
    id           => { data_type => 'int' },
    journal_day  => { data_type => 'int' },
    name         => { data_type => 'text' },
    start_time   => { data_type => 'datetime' },
    stop_time    => { data_type => 'datetime' },
    primary_link => { data_type => 'text' },
    project      => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( journal_day => 'Qublog::Schema::Result::JournalDay' );
__PACKAGE__->belongs_to( project => 'Qublog::Schema::Result::Task' );
__PACKAGE__->has_many( timers => 'Qublog::Schema::Result::JournalTimer', 'journal_entry' );
__PACKAGE__->has_many( comments => 'Qublog::Schema::Result::Comment', 'comment' );
__PACKAGE__->has_many( journal_entry_tags => 'Qublog::Schema::Result::JournalEntryTag', 'journal_entry' );
__PACKAGE__->many_to_many( tags => journal_entry_tags => 'tag' );

1;
