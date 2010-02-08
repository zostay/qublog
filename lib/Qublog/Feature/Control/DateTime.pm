package Qublog::Feature::Control::DateTime;
use Moose;

with qw(
    Form::Factory::Feature
    Form::Factory::Feature::Role::Control
    Form::Factory::Feature::Role::Clean
);

has parse_method => (
    is        => 'ro',
    isa       => 'Str',
    requierd  => 1,
    default   => 'parse_human_datetime',
);

has use_attribute_as_context => (
    is        => 'ro',
    isa       => 'Bool',
    required  => 1,
    default   => 0,
);

sub check_control { }

sub clean {
    my $self    = shift;
    my $action  = $self->action;
    my $control = $self->control;
    my $method  = $self->parse_method;

    # Set up the time zone if the action knows the preferred one
    my $time_zone = 'UTC';
    $time_zone = $action->time_zone
        if $action->does('Qublog::Action::Role::WantsTimeZone');

    # Use the action's original value as the context date if we're told to
    my $context_date;
    if ($self->use_attribute_as_context) {
        my $attr = $action->meta->find_attribute_by_name($control->name);
        $context_date = $attr->get_value($action);
    }
    
    # Parse the date
    my $value = $control->current_value;
    my $date  = Qublog::DateTime->$method($value, $time_zone, $context_date);
    $control->current_value($date);
}

package Form::Factory::Feature::Control::Custom::DateTime;
sub register_implementation { 'Qublog::Feature::Control::DateTime' }

1;
