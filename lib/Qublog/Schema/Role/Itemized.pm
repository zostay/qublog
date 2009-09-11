package Qublog::Schema::Role::Itemized;
use Moose::Role;

requires qw( as_journal_item list_journal_items );

1;
