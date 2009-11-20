package Qublog::Form::Factory::HTML;
use Moose;

with qw( Qublog::Form::Factory );

use Scalar::Util qw( blessed );

use Qublog::Form::Factory::HTML::Widget::Div;
use Qublog::Form::Factory::HTML::Widget::Input;
use Qublog::Form::Factory::HTML::Widget::Label;
use Qublog::Form::Factory::HTML::Widget::Select;
use Qublog::Form::Factory::HTML::Widget::Span;
use Qublog::Form::Factory::HTML::Widget::Textarea;

has renderer => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
    default   => sub { print @_ },
);

has consumer => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
    default   => sub { my %params = @_; $params{request} },
);

sub new_widget_for_control {
    my $self    = shift;
    my $control = shift;

    my $control_type = blessed $control;
    my ($name) = $control_type =~ /^Qublog::Form::Control::(\w+)$/;
    return unless $name;
    $name = lc $name;

    my $method = 'new_widget_for_' . $name;
    return $self->$method($control) if $self->can($method);
    return;
}

sub _wrapper($$@) {
    my ($name, $type, @widgets) = @_;

    return Qublog::Form::Factory::HTML::Widget::Div->new(
        id      => $name . '-wrapper',
        classes => [ qw( widget wrapper ), $type ],
        widgets => \@widgets,
    );
}

sub _label($$$) {
    my ($name, $type, $label) = @_;

    return Qublog::Form::Factory::HTML::Widget::Label->new(
        id      => $name . '-label',
        classes => [ qw( widget label ), $type ],
        for     => $name,
        content => $label,
    );
}

sub _input($$$;$%) {
    my ($name, $type, $input_type, $value, %args) = @_;

    return Qublog::Form::Factory::HTML::Widget::Input->new(
        id      => $name,
        name    => $name,
        type    => $input_type,
        classes => [ qw( widget field ), $type ],
        value   => $value || '',
        %args,
    );
}

sub _alerts($$) {
    my ($name, $type) = @_;

    return Qublog::Form::Factory::HTML::Widget::Span->new(
        id      => $name . '-alerts',
        classes => [ qw( widget alerts ), $type ],
        content => '',
    );
}

sub new_widget_for_button {
    my ($self, $control) = @_;

    return _input($control->name, 'button', 'submit', $control->label);
}

sub new_widget_for_checkbox {
    my ($self, $control) = @_;

    return _wrapper($control->name, 'checkbox', 
        _input($control->name, 'checkbox', 'checkbox', $control->value, 
            checked => $control->is_checked),
        _label($control->name, 'checkbox', $control->label),
        _alerts($control->name, 'checkbox'),
    );
}

sub new_widget_for_fulltext {
    my ($self, $control) = @_;

    return _wrapper($control->name, 'full-text',
        _label($control->name, 'full-text', $control->label),
        Qublog::Form::Factory::HTML::Widget::Textarea->new(
            id      => $control->name,
            name    => $control->name,
            classes => [ qw( widget field full-text ) ],
            content => $control->current_value,
        ),
        _alerts($control->name, 'full-text'),
    );
}

sub new_widget_for_password {
    my ($self, $control) = @_;

    return _wrapper($control->name, 'password',
        _label($control->name, 'password', $control->label),
        _input($control->name, 'password', $control->current_value),
        _alerts($control->name, 'password'),
    );
}

sub new_widget_for_selectmany {
    my ($self, $control) = @_;

    my @checkboxes;
    for my $choice (@{ $control->available_choices }) {
        push @checkboxes, _input(
            $choice->name, 'select-many choice', 'checkbox', 
            $choice->value, checked => $control->is_choice_selected($choice),
        );
    }

    return _wrapper($control->name, 'select-many',
        _label($control->name, 'select-many', $control->label),
        Qublog::Form::Factory::HTML::Widget::Div->new(
            id      => $control->name . '-list',
            classes => [ qw( widget list select-many ) ],
            widgets => \@checkboxes,
        ),
        _alerts($control->name, 'select-many'),
    );
}

sub new_widget_for_selectone {
    my ($self, $control) = @_;

    return _wrapper($control->name, 'select-one',
        _label($control->name, 'select-one', $control->label),
        Qublog::Form::Factory::HTML::Widget::Select->new(
            id       => $control->name,
            name     => $control->name,
            classes  => [ qw( widget field select-one ) ],
            size     => 1,
            available_choices => $control->available_choices,
            selected_choices  => [ $control->current_value ],
        ),
        _alerts($control->name, 'select-one'),
    );
}

sub new_widget_for_text {
    my ($self, $control) = @_;

    return _wrapper($control->name, 'text',
        _label($control->name, 'text', $control->label),
        _input($control->name, 'text', $control->current_value),
        _alerts($control->name, 'text'),
    );
}

sub new_widget_for_value {
    my ($self, $control) = @_;

    if ($control->is_visible) {
        return _wrapper($control->name, 'value',
            _label($control->name, 'value', $control->label),
            Qublog::Form::Factory::HTML::Widget::Span->new(
                id      => $control->name,
                content => $control->value,
                classes => [ qw( widget field value ) ],
            ),
            _alerts($control->name, 'text'),
        );
    }

    return;
}

sub render_control {
    my ($self, $control, %optiosn) = @_;

    my $widget = $self->new_widget_for_control($control);
    die "no widget found for $control" unless $widget;
    $self->renderer->($widget->render);
}

sub consume_control {
    my ($self, $control, %options) = @_;

    die "no request option passed" unless defined $options{request};

    die "HTML factory does not know how to consume values for $control"
        unless $control->does('Qublog::Form::Control::Role::ScalarValue')
            or $control->does('Qublog::Form::Control::Role::ListValue');

    my $widget = $self->new_widget_for_control($control);
    my $params = $widget->consume( params => $self->consumer->($options{request}) );

    return unless defined $params->{ $control->name };

    if ($control->does('Qublog::Form::Control::Role::ScalarValue')) {
        $control->current_value( $params->{ $control->name } );
    }
    else {
        $control->current_values( $params->{ $control->name } );
    }
}

1;
