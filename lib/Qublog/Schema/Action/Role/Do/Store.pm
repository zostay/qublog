package Qublog::Schema::Action::Role::Do::Store;
use Moose::Role;

#requires qw( find result_source );

sub do {
    my ($self, $options) = @_;

    my $object = $self->record;
    for my $column_name ($self->result_source->columns) {
        next unless $self->meta->has_attribute($column_name);

        my $attr = $self->meta->get_attribute($column_name);
        if ($attr->does('Form::Field')) {
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
