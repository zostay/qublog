package Qublog::Form::Widget::Select;
use Moose;

with qw( Qublog::Form::Widget );

extends qw( Qublog::Form::Widget::Element );

has '+tag_name' => (
    default => 'select',
);

has name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has size => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_size',
);

has multiple => (
    is        => 'ro',
    isa       => 'Bool',
);

has disabled => (
    is        => 'ro',
    isa       => 'Bool',
);

has tabindex => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_tabindex',
);

has available_options => (
    is        => 'ro',
    isa       => 'ArrayRef[Qublog::Form::Control::Select::Choice]',
    required  => 1,
    default   => sub { [] },
);

has selected_options => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    required  => 1,
    default   => sub { [] },
);

override more_attributes => sub {
    my $self = shift;

    my %attributes = (
        name  => $self->name,
    );

    $attributes{size}     = $self->size     if $self->has_size;
    $attributes{multiple} = 'multiple'      if $self->multiple;
    $attributes{disabled} = 'disabled'      if $self->disabled;
    $attributes{tabindex} = $self->tabindex if $self->has_tabindex;

    return \%attributes;
};

override render_content => sub {
    my $next = shift;
    my $self = shift;

    my %selected = map { $_ => 1 } @{ $self->selected_options };

    my $content = '';
    for my $option (@{ $self->available_options }) {
        $content .= '<option';
        $content .= ' value="' . $option->value . '"';
        $content .= ' selected="selected"' if $selected{ $option->value };
        $content .= '>' . $option->label . '</option>';
    }

    return $content;
};

sub process_control {
    my ($self, %options) = @_;
    my $params = $options{params};
    my $name   = $self->name;

    return { $name => $params->{ $name } };
}

1;
