use strict;
use warnings;

package Qublog::Action::UpdateComment;
use base qw/ Qublog::Action::Record::Update /;

use Qublog::Mixin::Action::CommentParser;

=head1 NAME

Qublog::Action::UpdateComment - update the comment

=head1 SYNOPSIS

  # Please add one

=head1 DESCRIPTION

This updates the comment. This performs a reparse of the comment along the way.

=head1 METHODS

=head2 record_class

Always returns C<Qublog::Model::Comment>.

=cut

sub record_class { 'Qublog::Model::Comment' }

=head2 take_action

This parses the comment and performs the C<take_action> method call on L<Jifty::Action::Record::Update>.

=cut

sub take_action {
    my $self = shift;

    $self->parse_comment_and_take_actions;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
