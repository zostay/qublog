package Qublog::Schema::Action::Role::Lookup;
use Moose::Role;

use Scalar::Util qw( blessed );

use Qublog::Schema::Feature::AutomaticLookup;

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

            # HACK This is an ugly kludge, but it works for the time being
            $value = $value->name if blessed $value and $value->isa('DateTime::TimeZone');

            $self->controls->{ $attr->name }->current_value($value);
        }
    }
};

1;
