package Qublog::Schema::Action::User::AgreeToTerms;
use Form::Factory::Processor;

with qw(
    Qublog::Schema::Action::Role::Model::User
    Qublog::Schema::Action::Role::Do::Store
    Qublog::Schema::Action::Role::Lookup::Find
);

has agreed_to_terms_md5 => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    traits    => [ 'Model::Column' ],
);

has_control agreement => (
    control   => 'button',
    options   => {
        label => 'I Agree to these Terms.',
    },
);

has_control disagreement => (
    control   => 'button',
    options   => {
        label => 'I Do Not Agree.',
    },
);

around run => sub {
    my $next = shift;
    my $self = shift;

    unless ($self->agreement) {
        $self->failure('You do not agree.');
        return;
    }

    return $self->$next(@_);
};

1;
