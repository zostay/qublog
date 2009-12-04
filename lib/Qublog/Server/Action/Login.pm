package Qublog::Server::Action::Login;
use Form::Factory::Processor;

has c => (
    is        => 'ro',
    isa       => 'Qublog::Server',
    required  => 1,
);

has_control username => (
    placement => 0,
    control   => 'text',
    options   => {
        label => 'Login Name',
    },
    features  => {
        required => 1,
    },
);

has_control password => (
    placement => 10,
    control   => 'password',
    features  => {
        required => 1,
    },
);

sub run {
    my $self = shift;
    my $c    = $self->c;

    my %args = (
        name     => $self->username,
        password => $self->password,
    );

    if ($c->authenticate(\%args)) {
        $self->result->success(
            sprintf('welcome back, %s', $self->username),
        );
    }

    else {
        $self->result->failure(
            'no account matches that username and password',
        );
    }
}

1;
