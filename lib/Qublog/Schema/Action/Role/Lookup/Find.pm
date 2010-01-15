package Qublog::Schema::Action::Role::Lookup::Find;
use Moose::Role;

with qw( Qublog::Schema::Action::Role::Lookup );

sub find {
    my $self = shift;

    my %lookup_values;
    my $result_source = $self->result_source;
    my %column_names = map { $_ => 1 } $result_source->primary_columns;

    for my $attr ($self->meta->get_all_attributes) {
        next unless $attr->does('Qublog::Schema::Action::Meta::Attribute::Column');
        next unless delete $column_names{ $attr->column_name };

        $lookup_values{ $attr->column_name } = $attr->get_value($self);
    }

    if (keys %column_names) {
        my $message = sprintf('unable to lookup a record because process %s for source %s does not have a value for column(s) %s', 
            ref $self, $self->result_source->source_name, 
            join(', ', keys %column_names)
        );
        die $message;
    }

    my $record = $result_source->resultset->find(\%lookup_values);
    if ($record) {
        $self->record($record);
    }
    else {
        $self->failure(
            sprintf('cannot find the %s you are looking for',
                $result_source->source_name)
        );
    }
}

1;
