use strict;
use warnings;

package Qublog::Model::JournalEntryCollection;
use base qw/ Qublog::TimedCollection /;

sub record_class { 'Qublog::Model::JournalEntry' }

1;
