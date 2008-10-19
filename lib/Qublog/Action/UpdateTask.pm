use strict;
use warnings;

=head1 NAME

Qublog::Action::UpdateTask

=cut

package Qublog::Action::UpdateTask;
use base qw/Qublog::Action::Record::Update/;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param custom_nickname =>
        label is 'Nickname',
        ajax validates,
        ;
};

sub record_class { 'Qublog::Model::Task' }

=head2 take_action

=cut

sub take_action {
    my $self = shift;
    
    my @names = $self->argument_names;
    my $task_log = Qublog::Model::TaskLog->new;
    $task_log->create(
        task     => $self->record,
        log_type => 'update',
    );

    $self->record->begin_update($task_log);
    $self->SUPER::take_action(@_);    
    $self->record->end_update;

    my $nickname = $self->argument_value( 'custom_nickname' );
    $self->record->add_nickname( $nickname ) if $nickname;
}

=head2 report_success

=cut

sub report_success {
    my $self = shift;
    # Your success message here
    $self->result->message('Updated task.');
}

1;

