package Qublog::Schema::Action::Role::Model;
use Moose::Role;

has schema => (
    is        => 'rw',
    isa       => 'Qublog::Schema',
    required  => 1,
);

has result_source => (
    is        => 'rw',
    isa       => 'DBIx::Class::ResultSource',
    required  => 1,
    handles   => [ qw( resultset ) ],
);

1;
