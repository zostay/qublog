package Qublog::Schema::Action::Role::Do;
use Moose::Role;

use Qublog::Schema::Action::Meta::Attribute::Column;

#requires qw( do schema success_message has_record );

sub run {
    my $self = shift;

    $self->schema->txn_do(sub {
        $self->find unless $self->has_record;
        $self->do;
    });

    if ($self->is_success) {
        my $message = $self->success_message;
        $self->result->success($message);
    }
}

1;
