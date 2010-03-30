package Qublog::Action::Role::Secure::CheckOwner;
use Form::Factory::Processor::Role;

with qw(
    Qublog::Action::Role::Secure
    Qublog::Action::Role::WantsCurrentUser
);

sub may_run {
    my $self = shift;

    my $attr = $self->meta->find_attribute_by_name('owner');
    if ($attr) {
        my $owner_id = $attr->does('Form::Factory::Action::Meta::Control')
                     ? $self->controls->{owner}->current_value
                     : $self->owner->id;

        unless ($self->current_user->id == $owner_id) {
            $self->error('you cannot do that for a different user');
            $self->is_valid(0);
        }
    }

    if ($self->does('Qublog::Schema::Action::Role::Lookup::Find')) {
        die "why hasn't the record loaded yet?" unless $self->has_record;
        unless ($self->current_user->id == $self->record->owner->id) {
            $self->error('you cannot work on a record for a different user');
            $self->is_valid(0);
        }
    }
}

1;
