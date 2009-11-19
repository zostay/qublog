package Qublog::Form::Cotnrol::SelectMany;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Role::AvailableChoices
    Qublog::Form::Control::Role::Labeled
    Qublog::Form::Control::Role::ListValue
);

use List::MoreUtils qw( any );

has selected_choices => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    required  => 1,
    predicate => 'has_selected_choices',
);

has default_selected_choices => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    predicate => 'has_default_selected_choices',
);

has '+stashable_keys' => (
    default   => [ qw( selected_choices ) ],
);

sub current_values {
    my $self = shift;

    return $self->has_selected_choices         ? $self->selected_choices
         : $self->has_default_selected_choices ? $self->default_selected_choices
         :                                       []
         ;
}

sub is_choice_selected {
    my ($self, $choice) = @_;

    return any { $_ eq $choice->value } @{ $self->current_values };
}

1;
