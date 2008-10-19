use strict;
use warnings;

package Qublog::CurrentUser;
use base qw/ Jifty::CurrentUser /;

sub user_object { 'Qublog::CurrentUser::SingleUser' }

package Qublog::CurrentUser::SingleUser;

sub id { 1 }

sub brief_description { 'me' }

sub time_zone { 'local' }

1;
