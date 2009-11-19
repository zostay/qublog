package Qublog::Form::Feature;
use Moose::Role;

requires qw( clean check pre_process post_process );

has action => (
    is        => 'ro',
    isa       => 'Qublog::Form::Action',
    required  => 1,
    weak_ref  => 1,
);

has message => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_message',
);

has result => (
    is        => 'ro',
    isa       => 'Qublog::Form::Result::Single',
    required  => 1,
    default   => sub { Qublog::Form::Result::Single->new },
);

sub feature_info {
    my $self    = shift;
    my $message = $self->message || shift;
    $self->result->info($message);
}

sub feature_warning {
    my $self    = shift;
    my $message = $self->message || shift;
    $self->result->warning($message);
}

sub feature_error {
    my $self    = shift;
    my $message = $self->message || shift;
    $self->result->error($message);
}

1;
