package Qublog::Schema::Action::Role::Model::User;
use Moose::Role;

with qw( Qublog::Schema::Action::Role::Model );

has '+result_source' => (
    lazy      => 1,
    default   => sub { shift->schema->source('User') },
);

1;
