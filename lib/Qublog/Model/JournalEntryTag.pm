use strict;
use warnings;

package Qublog::Model::JournalEntryTag;
use Jifty::DBI::Schema;

use Qublog::Record schema {
    column journal_entry =>
        references Qublog::Model::JournalEntry,
        is mandatory,
        ;

    column tag =>
        references Qublog::Model::Tag,
        is mandatory,
        ;
};

sub since { '0.6.0' }

sub owner { shift->journal_entry->owner }

sub current_user_can {
    my $self = shift;
    my ($op, %args) = @_;

    if ($op eq 'create') {
        my $journal_entry = $args{journal_entry};
        if (not ref $journal_entry) {
            $journal_entry = Qublog::Model::JournalEntry->new;
            $journal_entry->load($journal_entry);
        }

        return 1 if $self->current_user->owns($journal_entry);
    }

    if ($op eq 'delete') {
        return 1 if $self->current_user->owns($self);
    }

    return $self->SUPER::current_user_can(@_);
}

1;

