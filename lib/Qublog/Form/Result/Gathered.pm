package Qublog::Form::Result::Gathered;
use Moose;

use Scalar::Util qw( blessed refaddr );
use List::MoreUtils qw( all );

with qw( Qublog::Form::Result );

has _results => (
    is       => 'ro',
    isa      => 'HashRef[Qublog::Form::Result]',
    required => 1,
    default  => sub { {} },
);

sub results {
    my $self = shift;
    return values %{ $self->_results };
}

sub gather_results {
    my ($self, @results) = @_;

    my $results = $self->_results;
    for my $result (@results) {
        my $addr = refaddr $result;
        $results->{$addr} = $result;
    }
}

sub clear_results {
    my $self = shift;
    %{ $self->_results } = ();
}

sub clear_messages {
    my $self = shift;
    $_->clear_messages for $self->results;
}

sub clear_messages_for_field {
    my $self  = shift;
    my $field = shift;

    $_->clear_messages_for_field($field) for $self->results;
}

sub is_valid {
    my $self = shift;
    return all { $_->is_valid } $self->results;
}

sub is_validated {
    my $self = shift;
    return all { $_->is_validated } $self->results;
}

sub is_success {
    my $self = shift;
    return all { $_->is_success } $self->results;
}

sub is_outcome_known {
    my $self = shift;
    return all { $_->is_outcome_known } $self->results;
}

sub messages {
    my $self = shift;
    return [ map { @{ $_->messages } } $self->results ];
}

# Dumb merge
sub content {
    my $self = shift;
    return { map { %{ $_->content } } $self->results };
}

1;
