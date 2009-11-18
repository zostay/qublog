package Qublog::Form::Widget::Div;
use Moose;

with qw( Qublog::Form::Widget );

extends qw( Qublog::Form::Widget::Element );

has widgets => (
    is        => 'ro',
    isa       => 'ArrayRef',
    required  => 1,
    default   => sub { [] },
);

augment render_content => sub {
    my $self = shift;
    return $self->content . (inner() || '');
};

sub process_control {
    my $self = shift;
    my %args_accumulator;

    %args_accumulator = (%args_accumulator, $_->process(@_)) for @{ $self->widgets };

    return \%args_accumulator;
}

1;
