package Qublog::Schema::Result::CommentTag;
use Moose;
extends qw( Qublog::Schema::Result );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('comment_tags');
__PACKAGE__->add_columns(
    id      => { data_type => 'int' },
    comment => { data_type => 'int' },
    tag     => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( comment => 'Qublog::Schema::Result::Comment' );
__PACKAGE__->belongs_to( tag => 'Qublog::Schema::Result::Tag' );

1;
