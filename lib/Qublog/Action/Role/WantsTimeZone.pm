package Qublog::Action::Role::WantsTimeZone;
use Moose::Role;

has time_zone => (
    is        => 'ro',
    isa       => 'DateTime::TimeZone',
    required  => 1,
);

1;
