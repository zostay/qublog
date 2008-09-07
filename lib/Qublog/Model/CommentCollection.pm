use strict;
use warnings;

package Qublog::Model::CommentCollection;
use base qw/ Qublog::Collection /;

=head1 NAME

Qublog::Model::CommentCollection - a collection of journal comments

=head1 DESCRIPTION

This modifies the collection so that it is sorted by L<Qublog::Model::Comment/created_on> by default.

=cut

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    $self->order_by({ column => 'created_on', order => 'DES' });

    return $self;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
