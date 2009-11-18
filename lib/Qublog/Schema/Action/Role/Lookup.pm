package Qublog::Schema::Action::Role::Lookup;
use Moose::Role;

requires qw( find );

has record => (
    is        => 'rw',
    isa       => 'DBIx::Class::Row',
    predicate => 'has_record',
);

1;
