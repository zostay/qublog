package Qublog::Form::Control::FullText;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Labeled
);

has value => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_value',
);

has default_value => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_default_value',
);

sub current_value {
    my $self = shift;

    return $self->has_value         ? $self->value
         : $self->has_default_value ? $self->default_value
         :                            '';
}

1;