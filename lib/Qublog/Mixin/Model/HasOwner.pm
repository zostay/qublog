package Qublog::Mixin::Model::HasOwner;
use base qw( Jifty::DBI::Record::Plugin );

use Jifty::DBI::Schema;
use Jifty::DBI::Record schema {
    column owner =>
        references Qublog::Model::User,
        label is 'Owner',
        since '0.5.1',
        ;
};

sub register_triggers {
    my $self = shift;

    $self->add_trigger(
        name     => 'before_create',
        callback => \&before_create,
    );
}

sub before_create {
    my ($self, $args) = @_;

    if (not defined $args->{owner} and Jifty->web->current_user->id) {
        $args->{owner} = Jifty->web->current_user->id;
    }

    return 1;
}

1;
