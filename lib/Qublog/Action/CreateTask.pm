use strict;
use warnings;

package Qublog::Action::CreateTask;
use base qw/ Qublog::Action::Record::Create /;

sub record_class { 'Qublog::Model::Task' }

sub take_action {
    my $self = shift;

    my $nickname = $self->argument_value('alternate_nickname');
    my $name     = $self->argument_value('name');

    if (not defined $nickname and $name =~ /^\s*#?(\w+)\s*:\s*(.*)$/) {
        $nickname = $1;
        $name     = $2;

        $self->argument_value( alternate_nickname => $nickname );
        $self->argument_value( name               => $name );
    }

    $self->SUPER::take_action(@_);
}

sub report_success {
    my $self = shift;

    $self->result->success(
        _('Created new task #%1', $self->record->nickname)
    );
}

1
