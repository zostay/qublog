package Qublog::Form::Feature::Control::MatchAvailableChoices;
use Moose;

with qw( 
    Qublog::Form::Feature 
    Qublog::Form::Feature::Role::Control
);

sub check_control {
    my $self    = shift;
    my $control = $self->control;

    die "the match_available_options feature only works for controls that have available choices, not $control"
        unless $control->does('Qublog::Form::Control::Role::AvailableChoices');

    return if $control->does('Qublog::Form::Control::Role::ListValue');
    return if $control->does('Qublog::Form::Control::Role::ScalarValue');

    die "the match_available_feature does not know hwo to check the value of $control";
}

sub check_value {
    my $self    = shift;
    my $control = $self->control;

    my %available_values = map { $_->value => 1 } 
        @{ $self->control->available_choices };

    # Deal with scalar valued controls
    if ($control->does('Qublog::Form::Control::Role::ScalarValue')) {
        my $value = $control->current_value;
        $self->error('the given value for %s is not one of the available choices')
            unless $available_values{ $value };
    }

    # Deal with list valued controls
    else {
        my $values = $control->current_values;
        VALUE: for my $value (@$values) {
            unless ($available_values{ $value }) {
                $self->error('one of the values given for %s is not in the list of available choices');
                last VALUE;
            }
        }
    }
}

1;
