use strict;
use warnings;

=head1 NAME

Qublog::Action::Login

=cut

package Qublog::Action::Login;
use base qw/Qublog::Action Jifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param name => 
        label is 'Login Name',
        hints is 'This may be your name or email address.',
        is mandatory,
        ;

    param password =>
        label is 'Password',
        type is 'password',
        is mandatory,
        ;
};

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    
    my $name = $self->argument_value('name');
    my $pass = $self->argument_value('password');

    my $su = Qublog::CurrentUser->superuser;
    my $user = Qublog::Model::User->new( current_user => $su );
    $user->load_by_cols( name => $name );

    # Try email instead
    if (not $user->id) {
        $user->load_by_cols( email => $name );
    }

    if (not $user->id or not ($user->password eq $pass)) {
        $self->report_error;
        return;
    }

    my $current_user = Qublog::CurrentUser->new( id => $user->id );
    Jifty->web->current_user($current_user);
    $self->report_success;
}

=head2 report_error

=cut

sub report_error {
    my $self = shift;
    $self->result->error('No such user or wrong password.');
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    $self->result->message('Logged in.');
}

1;

