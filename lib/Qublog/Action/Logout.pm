use strict;
use warnings;

=head1 NAME

Qublog::Action::Logout

=cut

package Qublog::Action::Logout;
use base qw/Qublog::Action Jifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {

};

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    
    Jifty->web->current_user(Qublog::CurrentUser->new);
    
    $self->report_success if not $self->result->failure;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message('You are now logged out.');
}

1;

