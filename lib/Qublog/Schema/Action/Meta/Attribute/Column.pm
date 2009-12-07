package Qublog::Schema::Action::Meta::Attribute::Column;
use Moose::Role;

has column_name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    lazy      => 1,
    default   => sub { shift->name },
);

package Moose::Meta::Attribute::Custom::Trait::Model::Column;
sub register_implementation { 'Qublog::Schema::Action::Meta::Attribute::Column' }

1;
