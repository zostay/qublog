package Qublog::Action::Role::WantsCurrentUser;
use Moose::Role;

has current_user => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::User',
    required  => 1,
);

1;
