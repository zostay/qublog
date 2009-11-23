package Qublog::Schema::Action::Role::Lookup::New;
use Moose::Role;

with qw( Qublog::Schema::Action::Role::Lookup );

sub find {
    my $self = shift;
    $self->record($self->resultset->new_result({}));
}

1;
