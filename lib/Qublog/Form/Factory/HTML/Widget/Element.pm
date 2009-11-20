package Qublog::Form::Factory::HTML::Widget::Element;
use Moose;

with qw( Qublog::Form::Factory::HTML::Widget );

has tag_name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has id => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has classes => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    required  => 1,
    default   => sub { [] },
);

has attributes => (
    is        => 'ro',
    isa       => 'HashRef[Str]',
    required  => 1,
    default   => sub { {} },
);

has content => (
    is        => 'ro',
    isa       => 'Str',
    predicate => '_has_content',
);

sub has_content {
    my $self = shift;
    return $self->_has_content;
}

sub render_control {
    my ($self, %options) = @_;

    my $html = '<' . $self->tag_name;
    $html .= $self->render_id(%options);
    $html .= $self->render_class(%options);
    $html .= $self->render_attributes(%options);

    if ($self->has_content) {
        $html .= '>';
        $html .= $self->render_content(%options);
        $html .= '</' . $self->tag_name . '>';
    }

    else {
        $html .= '/>';
    }

    return $html;
}

sub render_content {
    my $self = shift;
    my $content = $self->content;
    return $self->content || '';
}

sub render_id {
    my $self = shift;
    return ' id="' . $self->id . '"';
}

sub render_class {
    my $self = shift;

    my @classes = ('form', @{ $self->classes });
    return ' class="' . join(' ', @classes) . '"';
}

sub render_attributes {
    my $self = shift;
    my @attributes;

    my %attributes = (
        %{ $self->attributes },
        %{ $self->more_attributes },
    );

    while (my ($name, $value) = each %attributes) {
        push @attributes, $name . '="' . $value . '"';
    }

    return join ' ', @attributes;
}

sub more_attributes { {} }

sub consume_control { }

1;
