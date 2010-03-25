package Qublog::Action::Role::Secure;
use Form::Factory::Processor::Role;

requires qw( may_run );

sub security_error { 'You are not authorized.' }

has_pre_processor check_may_run => sub {
    my $self = shift;
    die $self->security_error unless $self->may_run;
};

1;
