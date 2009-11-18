package Qublog::Form::Control::Button;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Role::Labeled
    Qublog::Form::Control::Role::ScalarValue
);

sub current_value { shift->label }

1;
