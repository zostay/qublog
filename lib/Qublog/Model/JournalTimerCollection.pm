use strict;
use warnings;

package Qublog::Model::JournalTimerCollection;
use base qw/ Qublog::TimedCollection /;

sub record_class { 'Qublog::Model::JournalTimer' }

1;
