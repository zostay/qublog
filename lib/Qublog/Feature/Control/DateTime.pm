package Qublog::Feature::Control::DateTime;
use Moose;

with qw(
    Form::Factory::Feature
    Form::Factory::Feature::Role::Control
    Form::Factory::Feature::Role::ControlValueConverter
);

has parse_method => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'parse_human_datetime',
);

has format_method => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'format_human_datetime',
);

has use_attribute_as_context => (
    is        => 'ro',
    isa       => 'Bool',
    required  => 1,
    default   => 0,
);

sub check_control { 
    my ($self, $control) = @_;

    die "only scalar valued controls are supported"
        unless $control->does('Form::Factory::Control::Role::ScalarValue');
    die "the control action must want a time zone"
        unless $control->action->does('Qublog::Action::Role::WantsTimeZone');
}

sub context_date {
    my $self    = shift;
    my $action  = $self->action;
    my $control = $self->control;

    # Use the action's original value as the context date if we're told to
    my $context_date;
    if ($self->use_attribute_as_context) {
        my $attr = $action->meta->find_attribute_by_name($control->name);
        $context_date = $attr->get_value($action);
    }

    return $context_date;
}
    
sub value_to_control {
    my ($self, $value) = @_;
    my $action = $self->action;
    my $format_datetime = $self->format_method;
    my $str = Qublog::DateTime->$format_datetime(
        $value,
        $action->time_zone,
        $self->context_date,
    );
    return $str;
}

sub control_to_value {
    my ($self, $value) = @_;
    my $action = $self->action;
    my $parse_datetime = $self->parse_method;
    return Qublog::DateTime->$parse_datetime(
        $value,
        $action->time_zone,
        $self->context_date,
    );
}

package Form::Factory::Feature::Control::Custom::DateTime;
sub register_implementation { 'Qublog::Feature::Control::DateTime' }

1;
