package Qublog::Schema::Feature::AutomaticLookup;
use Moose;

with qw( 
    Form::Factory::Feature 
    Form::Factory::Feature::Role::Clean
    Form::Factory::Feature::Role::PostProcess
);

has use_transaction => (
    is        => 'ro',
    isa       => 'Bool',
    required  => 1,
    default   => 1,
);

has _in_transaction => (
    is        => 'rw',
    isa       => 'Bool',
    required  => 1,
    default   => 0,
);

sub _begin_transaction {
    my $self = shift;
    my $schema = $self->action->schema;

    if ($self->use_transaction and not $self->_in_transaction) {
        $schema->txn_begin;
        $self->_in_transaction(1);
    }
}

sub _commit_transaction {
    my $self = shift;
    my $schema = $self->action->schema;

    if ($self->_in_transaction) {
        $schema->txn_commit;
        $self->_in_transaction(0);
    }
}

sub _rollback_transaction {
    my $self = shift;
    my $schema = $self->action->schema;

    if ($self->_in_transaction) {
        $schema->txn_rollback;
        $self->_in_transaction(0);
    }
}

sub clean {
    my $self = shift;
    my $action = $self->action;
    $self->_begin_transaction;

    return if $action->has_record;

    $action->find if $action->can_find;
};

sub post_process {
    my $self = shift;

    if ($self->action->is_success) {
        $self->_commit_transaction;
    }

    else {
        $self->_rollback_transaction;
    }
}

package Form::Factory::Feature::Custom::AutomaticLookup;
sub register_implementation { 'Qublog::Schema::Feature::AutomaticLookup' }

1;
