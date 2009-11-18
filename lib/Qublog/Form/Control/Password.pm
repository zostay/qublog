package Qublog::Form::Control::Password;
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

sub current_value {
    my $self = shift;

    return $self->has_value         ? $self->value
         :                            '';
}

1;