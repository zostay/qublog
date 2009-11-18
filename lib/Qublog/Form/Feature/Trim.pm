package Qublog::Form::Feature::Trim;
use Moose;

with qw( Qublog::Form::Feature );

sub check_control {
    my ($self, $control) = @_;

    return 1 if $self->does('Qublog::Form::Control::Role::ScalarValue');
    return;
}

sub clean_value {
    my ($self, $value) = @_;
    return trim($value);
}

1;
