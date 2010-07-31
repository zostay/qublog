use MooseX::Declare;

class Qublog::Server::Action::SelectSession 
        with (Qublog::Action::Role::Secure::AlwaysRun,
              Qublog::Action::Role::WantsCatalyst) {

    use Form::Factory::Processor;

    has_control session_id => (
        is        => 'ro',
        isa       => 'Int',

        control   => 'text',

        features  => {
            fill_on_assignment => 1,
            required           => 1,
        },
    );

    method run () {
        $self->c->session->{current_session_id} = $self->session_id;
    }
};

1;
