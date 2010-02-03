package Qublog::Action::Role::WantsToday;
use Moose::Role;

has today => (
    is        => 'ro',
    isa       => 'DateTime',
    required  => 1,
);

1;
