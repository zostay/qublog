package Qublog::Schema::Action::Role::Do::Create;
use Moose::Role;

requires qw( find result_source );

sub do {
    my $self = shift;

    my $object = $self->record;
    my $result_source = $self->result_source;

    for my $attr ($self->meta->get_all_attributes) {
        if ($attr->does('Qublog::Schema::Action::Meta::Attribute::Column')) {
            my $new_value = $attr->get_value($self);

            my $column_name = $attr->column_name;
            if ($result_source->has_column($column_name)) {
                $object->$column_name($new_value);
            }
            else {
                die "$result_set has no column named $column_name";
            }
        }
    }

    $object->insert;
}

sub success_message {
    my $self = shift;
    return sprintf('created a %s', $self->result_source->source_name);
}

1;
