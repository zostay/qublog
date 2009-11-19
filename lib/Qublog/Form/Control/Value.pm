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
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
);

has '+stashable_keys' => (
    default   => [ qw( value ) ],
);

sub current_value { 
    my $self = shift;
    $self->value(shift) if @_;
    return $self->value;
};

1;
