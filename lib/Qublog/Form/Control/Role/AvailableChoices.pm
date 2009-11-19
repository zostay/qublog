package Qublog::Form::Control::Role::AvailableChoices;
use Moose::Role;

has available_choices => (
    is        => 'ro',
    isa       => 'ArrayRef[Qublog::Form::Control::Choice]',
    required  => 1,
);

1;
