package Qublog::Schema::Role::Itemized;
use Moose::Role;

requires qw( as_journal_item list_journal_item_resultsets );

sub journal_items {
    my ($self, $c, $items) = @_;
    $items ||= {};

    my $resultsets = $self->list_journal_item_resultsets($c);
    for my $resultset (@$resultsets) {
        next unless $resultset;

        while (my $object = $resultset->next) {
            $object->journal_items($c, $items);
        }
    }

    $self->as_journal_item($c, $items);
    return $items;
}

1;
