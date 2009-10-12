package Qublog::Schema::Result::RemoteUser;
use Moose;

extends qw( Qublog::Schema::Result );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('remote_users');
__PACKAGE__->add_columns(
    id       => { data_type => 'int' },
    user     => { data_type => 'int' },
    name     => { data_type => 'text' },
    site_url => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( user => 'Qublog::Schema::Result::User' );

1;
