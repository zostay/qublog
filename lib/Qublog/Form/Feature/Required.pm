package Qublog::Form::Feature::Required;
use Moose::Role;

sub check_control {
    my ($self, $control) = @_;

    return 1 if $control->does('Qublog::Form::Control::Role::ScalarValue');
    return 1 if $control->does('Qublog::Form::Control::Role::ListValue');
    return;
}

sub validate_value {
    my ($self, $value) = @_;

    if ($control->does('Qublog::Form::Control::Role::ScalarValue')) {
        unless (length($value) > 0) {
            $self->error('the %s is required');
        }
    }
    else { # ($control->does('Qublog::Form::Control::Role::ListValue'))
        unless (@$value > 0) {
            $self->error('at least one value for %s is required');
        }
    }
}

1;
