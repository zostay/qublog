package Qublog::Schema::Action::Role::Do::Store;
use Moose::Role;

with qw( Qublog::Schema::Action::Role::Do );

#requires qw( find result_source );

sub do {
    my $self = shift;

    die "no record has been loaded" unless $self->has_record;

    my $record = $self->record;
    my $result_source = $self->result_source;

    for my $attr ($self->meta->get_all_attributes) {
        if ($attr->does('Qublog::Schema::Action::Meta::Attribute::Column')) {
            my $new_value = $attr->get_value($self);

            my $column_name = $attr->column_name;
            if ($result_source->has_column($column_name)) {
                $record->$column_name($new_value);
            }
            else {
                die "$result_source has no column named $column_name";
            }
        }
    }

    $record->update_or_insert;
}

sub success_message {
    my $self = shift;
    return sprintf('saved your %s', $self->result_source->source_name);
}

1;
