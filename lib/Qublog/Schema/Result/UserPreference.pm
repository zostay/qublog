package Qublog::Schema::Result::UserPreference;
use strict;
use warnings;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('user_preferences');
__PACKAGE__->add_columns(
    id    => { data_type => 'int' },
    user  => { data_type => 'int' },
    name  => { data_type => 'text' },
    value => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( user => 'Qublog::Schema::Result::User' );

1;
