package Qublog::Action::Role::Secure::NeverRun;
use Form::Factory::Processor::Role;

with qw( Qublog::Action::Role::Secure );

sub may_run {
    my $self = shift;
    $self->error('you are not authorized to do this');
    $self->is_valid(0);
}

1;
