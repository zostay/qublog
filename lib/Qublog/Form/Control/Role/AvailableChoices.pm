package Qublog::Form::Control::Role::AvailableChoices;
use Moose::Role;

use Qublog::Form::Control::Choice;

has available_choices => (
    is        => 'ro',
    isa       => 'ArrayRef[Qublog::Form::Control::Choice]',
    required  => 1,
);

1;
