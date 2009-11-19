package Qublog::Form::Feature;
use Moose::Role;

requires qw( check_control );

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

sub clean {
    my ($self, $value, %options) = @_;

    return $self->clean_value($value, %options) if $self->can('clean_value');
    return $value;
}

sub check {
    my ($self, $value, %options) = @_;
    $self->check_value($value, %options) if $self->can('check_value');
}

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
