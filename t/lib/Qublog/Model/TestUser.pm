use strict;
use warnings;

package Qublog::Model::TestUser;
use base qw/ Qublog::Record /;

use Jifty::DBI::Schema;
use Qublog::Record schema {
column password =>
    type is 'text',
    filters are qw/ Qublog::Filter::SaltHash /;
};

1
