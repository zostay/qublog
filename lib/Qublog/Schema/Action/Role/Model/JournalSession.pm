package Qublog::Schema::Action::Role::Model::JournalSession;
use Moose::Role;

with qw( Qublog::Schema::Action::Role::Model );

has result_source => (
    is        => 'rw',
    isa       => 'DBIx::Class::ResultSource',
    required  => 1,
    handles   => [ qw( resultset ) ],
    lazy      => 1,
    default   => sub { shift->schema->source('JournalSession') },
);

1;
