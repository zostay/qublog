package Qublog::Form::ControlFactory::Standard;
use Moose;

with qw( Qublog::Form::ControlFactory );

use Qublog::Form::Control::Checkbox;
use Qublog::Form::Control::FullText;
use Qublog::Form::Control::Password;
use Qublog::Form::Control::SelectMany;
use Qublog::Form::Control::SelectOne;
use Qublog::Form::Control::Text;
use Qublog::Form::Control::Value;

use Qublog::Form::Widget::Div;
use Qublog::Form::Widget::Input;
use Qublog::Form::Widget::Label;
use Qublog::Form::Widget::Select;
use Qublog::Form::Widget::Span;
use Qublog::Form::Widget::Textarea;

sub new_widget_for_control {
    my $self = shift;
    my $name = shift;

    return if $name =~ /\W/;

    my $method = 'new_widget_for' . $name;
    return $self->$method(@_) if $self->can($method);
    return;
}

sub _wrapper($$@) {
    my ($name, $type, @widgets) = @_;

    return Qublog::Form::Widget::Div->new(
        id      => $name . '-wrapper',
        classes => [ qw( widget wrapper ), $type ) ],
        widgets => \@widgets,
    );
}

sub _label($$$) {
    my ($name, $type, $label) = @_;

    return Qublog::Form::Widget::Label->new(
        id      => $name . '-label',
        classes => [ qw( widget label ), $type ],
        for     => $name,
        content => $label,
    );
}

sub _input($$$$%) {
    my ($name, $type, $input_type, $value, %args) = @_;

    return Qublog::Form::Widget::Input->new(
        id      => $name,
        name    => $name,
        type    => $input_type,
        classes => [ qw( widget field ), $type ],
        value   => $value,
        %args,
    );
}

sub _alerts($$) {
    my ($name, $type) = @_;

    return Qublog::Form::Widget::Span->new(
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

sub new_widget_for_full_text {
    my ($self, $control) = @_;

    return _wrapper($control->name, 'full-text',
        _label($control->name, 'full-text', $control->label),
        Qublog::Form::Widget::Textarea->new(
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
        _label($control->name, 'password', 'password', $control->label),
        _input($control->name, 'password', $control->current_value),
        _alerts($control->name, 'password'),
    );
}

sub new_widget_for_select_many {
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
        Qublog::Form::Widget::Div->new(
            id      => $control->name . '-list',
            classes => [ qw( widget list select-many ) ],
            widgets => \@checkboxes,
        ),
        _alerts($control->name, 'select-many'),
    );
}

sub new_widget_for_select_one {
    my ($self, $control) = @_;

    return _wrapper($control->name, 'select-one',
        _label($control->name, 'select-one', $control->label),
        Qublog::Form::Widget::Select->new(
            id       => $control->name,
            name     => $control->name,
            classes  => [ qw( widget field select-one ) ],
            size     => 1,
            options  => $control->available_choices,
            selected => [ $control->current_value ],
        ),
        _alerts($control->name, 'select-one'),
    );
}

sub new_widget_for_text {
    my ($self, $control) = @_;

    return _wrapper($control->name, 'text',
        _label($control->name, 'text', 'text', $control->label),
        _input($control->name, 'text', $control->current_value),
        _alerts($control->name, 'text'),
    );
}

sub new_widget_for_value {
    my ($self, $control) = @_;

    if ($control->is_visible) {
        return _wrapper($control->name, 'value',
            _label($control->name, 'value', $control->label),
            Qublog::Form::Widget::Span->new(
                id      => $control->name,
                content => $control->value,
                classes => [ qw( widget field value ) ],
            ),
            _alerts($control->name, 'text'),
        );
    }

    return;
}

1;
