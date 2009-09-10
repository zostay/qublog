package Qublog::Schema::Result::User;
use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('users');
__PACKAGE__->add_columns(
    id             => { data_type => 'int' },
    name           => { data_type => 'text' },
    email          => { data_type => 'text' },
    email_verified => { data_type => 'boolean' },
    password       => { data_type => 'text' },
    time_zone      => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('id');

sub self_check { return 0 }

1;
