package Qublog::Form::Feature::Control::Trim;
use Moose;

with qw( 
    Qublog::Form::Feature 
    Qublog::Form::Feature::Role::Control
);

sub check_control {
    my ($self, $control) = @_;

    return if $control->does('Qublog::Form::Control::Role::ScalarValue');

    die "the trim feature only works on scalar values, not $control";
}

sub clean_value {
    my $self    = shift;
    my $control = $self->control;

    my $value   = $control->current_value;
    $value =~ s/^\s*//;
    $value =~ s/\s*$//;

    $control->current_value($value);
}

1;
