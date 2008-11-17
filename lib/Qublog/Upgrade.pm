use strict;
use warnings;

package Qublog::Upgrade;
use base qw/ Jifty::Upgrade /;
use Jifty::Upgrade qw/ since /;

=head1 NAME

Qublog::Upgrade - upgrade script for the Qublog application

=head1 UPGRADES

=head2 0.4.0

I didn't like how nicknames worked in 0.3.0. I'm using a less hacky solution by collapsing the Nicknames into Tags and eliminating the magic C<kind>/C<object_id> mapping used. Instead, I'm expanding to regular link tables. Eventually, I may have a nickname link table to link "reference tags" (i.e., nicknames) to the objects, but I'm not going to use a magic reference without enforcing referential integrity in the future.

=cut

since '0.4.0' => sub {
    my $dbh = Jifty->handle->dbh;
    my $tags_sth = $dbh->do(qq{
        DELETE FROM tags
    });

    my $nicknames_sth = $dbh->prepare(qq{
        SELECT * FROM nicknames
    });
    $nicknames_sth->execute;

    my $tag = Qublog::Model::Tag->new;
    my $task_tag = Qublog::Model::TaskTag->new;

    while (my $nickname = $nicknames_sth->fetchrow_hashref) {
        $tag->create(
            name => $nickname->{nickname},
        );
        die "Could not create tag $nickname->{nickname}"
            unless $tag->id;

        if ($nickname->{kind} eq 'Task') {
            $task_tag->create(
                task   => $nickname->{object_id},
                tag    => $tag,
                sticky => $nickname->{sticky},
            );
        }
    }
};

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;
