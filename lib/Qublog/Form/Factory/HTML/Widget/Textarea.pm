package Qublog::Form::Widget::Textarea;
use Moose;

with qw( Qublog::Form::Widget );

extends qw( Qublog::Form::Widget::Element );

has name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has rows => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_rows',
);

has cols => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_cols',
);

override more_attributes => (
    my $self = shift;

    my %attributes = (
        name => $self->name,
    );

    $attributes{rows} = $self->rows if $self->has_rows;
    $attributes{cols} = $self->cols if $self->has_cols;

    return \%attributes;
}

sub process_control {
    my ($self, %options) = @_;
    my $params = $options{params};
    my $name   = $self->name;

    return { $name => $params->{ $name } };
}

1;
