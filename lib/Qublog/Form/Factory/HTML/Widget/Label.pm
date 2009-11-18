package Qublog::Form::Widget::Label;
use Moose;

with qw( Qublog::Form::Widget Qublog::Form::Widget::Element );

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

sub process_control { }

1;
