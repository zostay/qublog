use strict;
use warnings;

=head1 NAME

Qublog::Action::GoToDate

=cut

package Qublog::Action::GoToDate;
use base qw/Qublog::Action Jifty::Action/;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param date => 
        label is 'Go to',
        type is 'date',
        is mandatory,
        default is 'today',
        ;
};

=head2 take_action

=cut

sub take_action {
    my $self = shift;

    my $date = $self->argument_value('date');

    Jifty->web->next_page(
        Jifty::Web::Form::Clickable->new(
            url          => '/journal',
            parameters   => {
                date => $date,
            },
        )
    );
    Jifty->web->force_redirect(1);
    
    return 1;
}

1;

