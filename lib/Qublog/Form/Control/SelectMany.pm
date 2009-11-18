package Qublog::Form::Cotnrol::SelectMany;
use Moose;

with qw(
    Qublog::Form::Control
    Qublog::Form::Control::Role::Labeled
);

use List::MoreUtils qw( any );

has available_choices => (
    is        => 'ro',
    isa       => 'ArrayRef[Qublog::Form::Control::Choice]',
    required  => 1,
);

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

sub current_selected_choices {
    my $self = shift;

    return $self->has_selected_choices         ? $self->selected_choices
         : $self->has_default_selected_choices ? $self->default_selected_choices
         :                                       []
         ;
}

sub is_choice_selected {
    my ($self, $choice) = @_;

    return any { $_ eq $choice->value } @{ $self->current_selected_choices };
}

1;
