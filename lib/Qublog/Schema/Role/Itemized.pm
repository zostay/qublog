package Qublog::Schema::Role::Itemized;
use Moose::Role;

requires qw( as_journal_item list_journal_item_resultsets );

sub journal_items {
    my ($self, $options, $items) = @_;
    $items ||= {};

    my $resultsets = $self->list_journal_item_resultsets($options);
    for my $resultset (@$resultsets) {
        next unless $resultset;

        while (my $object = $resultset->next) {
            $object->journal_items($options, $items);
        }
    }

    $self->as_journal_item($options, $items);
    return $items;
}

1;
