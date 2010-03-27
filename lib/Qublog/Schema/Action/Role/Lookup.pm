package Qublog::Schema::Action::Role::Lookup;
use Form::Factory::Processor::Role;

use Scalar::Util qw( blessed );

use Qublog::Schema::Feature::AutomaticLookup;

use_feature 'automatic_lookup';

requires qw( can_find find );

has record => (
    is        => 'rw',
    isa       => 'DBIx::Class::Row',
    predicate => 'has_record',
);

sub prefill_from_record {
    my $self = shift;

    if ($self->has_record) {
        my $record = $self->record;

        for my $attr ($self->meta->get_all_attributes) {
            next unless $attr->does('Qublog::Schema::Action::Meta::Attribute::Column');

            my $column_name = $attr->column_name;

            my $value = $record->$column_name;

            if (defined $value) {
                $attr->set_value($self, $value);
            }
            else {
                $attr->clear_value($self, $value);
            }
        }
    }
};

1;
