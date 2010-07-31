use MooseX::Declare;

role Qublog::Action::Role::WantsCatalyst {
    has c => (
        is        => 'ro',
        isa       => 'Qublog::Server',
        required  => 1,
    );
};

1;
