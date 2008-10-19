use strict;
use warnings;

package Qublog::Action::CreateTask;
use base qw/ Qublog::Action::Record::Create /;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param custom_nickname =>
        label is 'Nickname',
        ajax validates,
        ;
};

sub record_class { 'Qublog::Model::Task' }

sub take_action {
    my $self = shift;

    my $nickname = $self->argument_value('custom_nickname');
    my $name     = $self->argument_value('name');

    if (not defined $nickname and $name =~ /^\s*#?(\w+)\s*:\s*(.*)$/) {
        $nickname = $1;
        $name     = $2;

        $self->argument_value( custom_nickname => undef );
        $self->argument_value( name            => $name );
    }

    $self->SUPER::take_action(@_);

    $self->record->add_nickname( $nickname ) if $nickname;
}

sub report_success {
    my $self = shift;

    $self->result->success(
        _('Created new task #%1', $self->record->nickname)
    );
}

sub validate_custom_nickname {
    my ($self, $value) = @_;

    if ($value =~ /[^0-9A-Z]/) {
        return $self->validation_error(
            custom_nickname => _('A custom nickname may only contain letters and numbers.'),
        );
    }

    return 1;
}

1
