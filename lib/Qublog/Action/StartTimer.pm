use strict;
use warnings;

=head1 NAME

Qublog::Action::StartTimer

=cut

package Qublog::Action::StartTimer;
use base qw/Qublog::Action::Record::Delete/;

sub record_class { 'Qublog::Model::JournalEntry' }

=head2 take_action

=cut

sub take_action {
    my $self = shift;

    $self->record->start_timer;
    
    $self->report_success if not $self->result->failure;
    
    return 1;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    $self->result->message(_('Started'));
}

1;
