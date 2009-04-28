use strict;
use warnings;

package Qublog::Model::CommentTag;
use Jifty::DBI::Schema;

use Qublog::Record schema {
    column comment =>
        references Qublog::Model::Comment,
        is mandatory,
        ;

    column tag =>
        references Qublog::Model::Tag,
        is mandatory,
        ;
};

sub since { '0.6.0' }

sub current_user_can {
    my $self = shift;
    my ($op, %args) = @_;

    if ($op eq 'create') {
        my $comment = $args{comment};
        if (not ref $comment) {
            $comment = Qublog::Model::Comment->new;
            $comment->load($comment);
        }

        return 1 if $comment->id 
                and $comment->owner->id == Jifty->web->current_user->id;
    }

    if ($op eq 'delete') {
        return 1 if $self->comment->id
                and $self->comment->owner->id == Jifty->web->current_user->id;
    }

    return $self->SUPER::current_user_can(@_);
}

1;

