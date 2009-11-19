package Qublog::Form::Factory::HTML::Widget::Label;
use Moose;

with qw( Qublog::Form::Factory::HTML::Widget );

extends qw( Qublog::Form::Factory::HTML::Widget::Element );

has for => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has '+content' => (
    required  => 1,
);

override more_attributes => sub {
    my $self = shift;

    return {
        for => $self->for,
    };
};

sub consume_control { }

1;
