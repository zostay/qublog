use strict;
use warnings;

package Qublog::CurrentUser;
use base qw/ Jifty::CurrentUser /;

sub _init {
    my $self = shift;
    my %args = @_;

    if (keys %args) {
        my $user = Qublog::Model::User->new( current_user => $self );
        $user->load_by_cols(%args);
        
        $self->user_object($user);
    }

    return 1;
}

1;
