package Qublog::Form::Control::Value;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Role::Labeled
    Qublog::Form::Control::Role::ScalarValue
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

has '+stashable_keys' => (
    default   => [ qw( value ) ],
);

sub current_value { shift->value };

1;
