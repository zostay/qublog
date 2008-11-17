use strict;
use warnings;

package Qublog::Action::CreateTask;
use base qw/ Qublog::Action::Record::Create /;

use Jifty::Param::Schema;
use Jifty::Action schema {
    param tag_name =>
        label is 'Tag',
        ajax validates,
        ;
};

sub record_class { 'Qublog::Model::Task' }

sub take_action {
    my $self = shift;

    my $nickname = $self->argument_value('tag_name');
    my $name     = $self->argument_value('name');

    if (not defined $nickname and $name =~ /^\s*#?(\w+)\s*:\s*(.*)$/) {
        $nickname = $1;
        $name     = $2;

        $self->argument_value( tag_name => undef );
        $self->argument_value( name     => $name );
    }

    $self->argument_value('tag_name' => undef);

    $self->SUPER::take_action(@_);

    $self->record->add_tag( $nickname ) if $nickname;
}

sub report_success {
    my $self = shift;

    $self->result->success(
        _('Created new task #%1', $self->record->tag)
    );
}

sub validate_tag_name {
    my ($self, $value) = @_;

    if ($value =~ /[^0-9A-Z]/) {
        return $self->validation_error(
            tag_name => _('A custom tag may only contain letters and numbers.'),
        );
    }

    return 1;
}

1
