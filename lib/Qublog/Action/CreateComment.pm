use strict;
use warnings;

package Qublog::Action::CreateComment;
use base qw/ Qublog::Action::Record::Create /;

use Qublog::Mixin::Action::CommentParser;

sub record_class { 'Qublog::Model::Comment' }

sub take_action {
    my $self = shift;

    $self->parse_comment_and_take_actions;
}

1;
