package Qublog::Form::Feature::Control::Trim;
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
    my $self    = shift;
    my $control = $self->control;
    my $value   = $control->current_value;
    $control->current_value(trim($value));
}

1;
