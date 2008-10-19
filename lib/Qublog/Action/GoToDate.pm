use strict;
use warnings;

package Qublog::Action::GoToDate;
use base qw/Qublog::Action Jifty::Action/;

=head1 NAME

Qublog::Action::GoToDate - jump to a different date in the journal

=head1 DESCRIPTION

This action provides a date control that when selected, jumps you to the journal for that day.

=head1 SCHEMA

=head2 date

This is the control for picking the date.

=cut

use Jifty::Param::Schema;
use Jifty::Action schema {
    param date => 
        label is 'Go to',
        type is 'date',
        is mandatory,
        is sticky_on_success,
        default is 'today',
        ;
};

=head2 take_action

This jumps to the journal on the date in the date control.

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

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

This is free software. You may modify and distribute it under the terms of the Artistic 2.0 license.

=cut


1;

