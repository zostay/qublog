package Qublog::Form::Feature::MatchAvailableChoices;
use Moose;

with qw( Qublog::Form::Feature );

sub check_control {
    my ($self, $control) = @_;

    return unless $control->does('Qublog::Form::Control::Role::ListValue');
    return unless $control->does('Qublog::Form::Control::Role::AvailableChoices');
    return 1;
}

sub validate_value {
    my ($self, $values) = @_;

    my %available_values = map { $_->value => 1 } 
        @{ $self->control->available_choices };
    for my $value (@$values) {
        $self->error('found an unexpected selection for %s')
            unless $available_values{ $value };
    }
}

1;
