package Qublog::Form::Feature::Trim;
use Moose;

with qw( 
    Qublog::Form::Feature 
    Qublog::Form::Feature::Role::Control
);

sub check_control {
    my ($self, $control) = @_;

    return if $self->does('Qublog::Form::Control::Role::ScalarValue');

    die "the trim feature only works on scalar values, not $control";
}

sub clean_value {
    my $self  = shift;
    my $value = $self->control->current_value;
    return trim($value);
}

1;
