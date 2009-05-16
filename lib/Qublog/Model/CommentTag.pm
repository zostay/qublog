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

sub owner { shift->comment->owner }

sub current_user_can {
    my $self = shift;
    my ($op, %args) = @_;

    if ($op eq 'create') {
        my $comment = $args{comment};
        if (not ref $comment) {
            $comment = Qublog::Model::Comment->new;
            $comment->load($comment);
        }

        return 1 if $self->current_user->owns($comment);
    }

    if ($op eq 'delete') {
        return 1 if $self->current_user->owns($self);
    }

    return $self->SUPER::current_user_can(@_);
}

1;

