package Qublog::Schema::Action::Role::Model;
use Moose::Role;

has schema => (
    is        => 'rw',
    isa       => 'Qublog::Schema',
    required  => 1,
);

1;
