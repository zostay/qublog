package Qublog::Form::Control::Password;
use Moose;

with qw( 
    Qublog::Form::Control 
    Qublog::Form::Control::Role::Labeled
    Qublog::Form::Control::Role::ScalarValue;
);

has value => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_value',
);

sub current_value {
    my $self = shift;
    $self->value(shift) if @_;
    return $self->has_value         ? $self->value
         :                            '';
}

1;
