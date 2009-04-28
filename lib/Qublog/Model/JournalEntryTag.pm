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

sub current_user_can {
    my $self = shift;
    my ($op, %args) = @_;

    if ($op eq 'create') {
        my $journal_entry = $args{journal_entry};
        if (not ref $journal_entry) {
            $journal_entry = Qublog::Model::JournalEntry->new;
            $journal_entry->load($journal_entry);
        }

        return 1 if $journal_entry->id 
                and $journal_entry->owner->id == Jifty->web->current_user->id;
    }

    if ($op eq 'delete') {
        return 1 if $self->journal_entry->id
                and $self->journal_entry->owner->id 
                    == Jifty->web->current_user->id;
    }

    return $self->SUPER::current_user_can(@_);
}

1;

