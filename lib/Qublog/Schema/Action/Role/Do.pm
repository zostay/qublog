package Qublog::Schema::Action::Role::Do;
use Moose::Role;

requires qw( do schema success_message has_record );

sub run {
    my ($self, $options) = @_;

    $self->schema->txn_do(sub {
        $self->find($options) unless $self->has_record;
        $self->do($options);
    });

    if ($self->result->is_success) {
        my $message = $self->success_message;
        $self->result->success($message);
    }
}

1;
