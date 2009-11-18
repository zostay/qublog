package Qublog::Form::Result::Gathered;
use Moose;

use List::MoreUtils qw( all );

with qw( Qublog::Form::Result );

has results => (
    is       => 'ro',
    isa      => 'ArrayRef[Qublog::Form::Result]',
    required => 1,
    default  => sub { [] },
);

sub gather_results {
    my ($self, @results) = @_;
    push @{ $self->results }, @results;
}

sub is_valid {
    my $self = shift;
    return all { $_->is_valid } @{ $self->results };
}

sub is_validated {
    my $self = shift;
    return all { $_->is_validated } @{ $self->results };
}

sub is_success {
    my $self = shift;
    return all { $_->is_success } @{ $self->results };
}

sub is_otucome_known {
    my $self = shift;
    return all { $_->is_outcome_known } @{ $self->results };
}

sub messages {
    my $self = shift;
    return [ map { @{ $_->messages } } @{ $self->results } ];
}

# Dumb merge
sub content {
    my $self = shift;
    return { map { %{ $_->content } } @{ $self->results } };
}

1;