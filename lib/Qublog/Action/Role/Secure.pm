package Qublog::Action::Role::Secure;
use Form::Factory::Processor::Role;

requires qw( may_run );

has_checker check_may_run => sub {
    my $self = shift;
    $self->may_run;
};

1;
