package Qublog::Schema::Action::Role::Do::Store;
use Moose::Role;

with qw( Qublog::Schema::Action::Role::Do );

#requires qw( find result_source );

sub do {
    my $self = shift;

    my $object = $self->record;
    for my $column_name ($self->result_source->columns) {
        my $attr = $self->meta->find_attribute_by_name($column_name);
        next unless defined $attr;

        if ($attr->does('Form::Factory::Action::Meta::Attribute::Control')) {
            my $new_value = $attr->get_value($self);
            $object->$column_name($new_value);
        }
    }

    $object->update_or_insert;
}

sub success_message {
    my $self = shift;
    return sprintf('saved your %s', $self->result_source->source_name);
}

1;
