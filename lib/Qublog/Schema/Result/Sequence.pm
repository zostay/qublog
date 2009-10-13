package Qublog::Schema::Result::Sequence;
use Moose;

extends qw( Qublog::Schema::ResultSet );

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('sequences');
__PACKAGE__->add_columns(
    id         => { data_type => 'int' },
    last_value => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');

sub next_value {
    my ($self, $filter) = @_;
    my $next_value = $self->last_value + 1;

    until (not $filter or $filter->($next_value)) { $next_value++ }
    $self->last_value($next_value);

    return $next_value;
}

1;
