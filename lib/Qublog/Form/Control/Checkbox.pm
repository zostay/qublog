package Qublog::Form::Control::Checkbox;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Role::Labeled
);

has value => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 1,
);

has is_checked => (
    is        => 'ro',
    isa       => 'Bool',
    required  => 1,
    default   => 0,
);

1;
