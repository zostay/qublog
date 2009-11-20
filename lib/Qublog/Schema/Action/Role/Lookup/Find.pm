package Qublog::Schema::Action::Role::Lookup::Find;
use Moose;

sub find {
    my $self = shift;

    my %lookup_values;
    for my $column_name ($self->result_source->primary_columns) {
        my $attr = $self->meta->get_attribute($column_name);
        unless ($attr and $attr->does('Form::Field')) {
            my $message = sprintf('unable to lookup a record because process %s for source %s does not have a widget for column %s', 
                ref $self, $self->result_source->source_name, $column_name
            );
            die $message;
        }

        $lookup_values{ $column_name } = $attr->get_value($self);
    }

    my $record = $self->result_source->resultset->find(\%lookup_values);
    if ($record) {
        $self->record($record);
    }
    else {
        $self->result->error({
            message => sprintf('cannot find the %s you are looking for',
                $self->result_source->source_name),
        });
    }
}

1;
