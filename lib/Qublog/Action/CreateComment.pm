use strict;
use warnings;

package Qublog::Action::CreateComment;
use base qw/ Qublog::Action::Record::Create /;

use Qublog::Mixin::Action::CommentParser;

=head1 NAME

Qublog::Action::CreateComment - create a comment

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

This creates a comment. This is handled within a transaction and performs an initial create of the action, parses the comment, then updates the comment with the post-parse transformed text.

=head1 METHODS

=head2 record_class

This always returns C<Qublog::Model::Comment>.

=cut

sub record_class { 'Qublog::Model::Comment' }

=head2 take_action

This creates a comment, parses the text of the comment, and then updates the comment text fallowing the parse.

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
