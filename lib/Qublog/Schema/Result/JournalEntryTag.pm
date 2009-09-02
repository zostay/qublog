package Qublog::Schema::Result::JournalEntryTag;
use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('journal_entry_tags');
__PACKAGE__->add_columns(
    id            => { data_type => 'int' },
    journal_entry => { data_type => 'int' },
    tag           => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( journal_entry => 'Qublog::Schema::Result::JournalEntry' );
__PACKAGE__->belongs_to( tag => 'Qublog::Schema::Result::Tag' );

1;
