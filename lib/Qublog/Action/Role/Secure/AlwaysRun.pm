package Qublog::Action::Role::Secure::AlwaysRun;
use Form::Factory::Processor::Role;

with qw( Qublog::Action::Role::Secure );

sub may_run { 1 };

1;
