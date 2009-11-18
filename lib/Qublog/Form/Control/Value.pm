package Qublog::Form::Control::Value;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Role::Labeled
);

has is_visible => (
    is        => 'ro',
    isa       => 'Bool',
    required  => 1,
    default   => 0,
);

has value => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

1;
