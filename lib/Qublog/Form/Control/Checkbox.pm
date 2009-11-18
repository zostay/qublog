package Qublog::Form::Control::Checkbox;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Role::Labeled
    Qublog::Form::Control::Role::ScalarValue
);

has checked_value => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 1,
);

has unchecked_value => (
    is        => 'ro',
    isa       => 'Str',
    requried  => 1,
    default   => 0,
);

has is_checked => (
    is        => 'ro',
    isa       => 'Bool',
    required  => 1,
    default   => 0,
);

sub current_value {
    my $self = shift;
    return $self->is_checked ? $self->checked_value : $self->unchecked_value;
}

1;
