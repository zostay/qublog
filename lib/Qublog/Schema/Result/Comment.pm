package Qublog::Schema::Result::Comment;
use Moose;
extends qw( Qublog::Schema::Result );

with qw( Qublog::Schema::Role::Itemized );

=head1 NAME

Qublog::Schema::Result::Comment - a table for comments

=head1 DESCRIPTION

A table for comments.

=head1 SCHEMA

=head2 id

The autogenerated ID column.

=head2 journal_day

The L<Qublog::Schema::Result::JournalDay> on which this comment was recorded.

=head2 journal_timer

The (optional) L<Qublog::Schema::Result::JournalTimer> this comment is attached to.

=head2 created_on

The date and time when the comment was creaetd.

=head2 name

The content of the comment.

=head2 processed_name_cache

A HTMLified version of the comment. Since converting a comment to HTML is time consuming and would have to be done frequently without this.

=head2 owner

The L<Qublog::Schema::Result::User> that was logged when the comment was created.

=head2 task_logs

Result set of the L<Qublog::Schema::Result::TaskLog> attached to this comment.

=head2 comment_tags

Result set of the L<Qublog::Schema::Result::CommentTag>s attached to this comment.

=head2 tags

Result set of the L<Qublog::Schema::Result::Tag>s attached through L</comment_tags>.

=cut

__PACKAGE__->load_components(qw( InflateColumn::DateTime Core ));
__PACKAGE__->table('comments');
__PACKAGE__->add_columns(
    id            => { data_type => 'int' },
    journal_day   => { data_type => 'int' },
    journal_timer => { data_type => 'int' },
    created_on    => { data_type => 'datetime', timezone => 'UTC' },
    name          => { data_type => 'text' },
    processed_name_cache => { data_type => 'text' },
    owner         => { data_type => 'int' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to( journal_day => 'Qublog::Schema::Result::JournalDay' );
__PACKAGE__->belongs_to( journal_timer => 'Qublog::Schema::Result::JournalTimer' );
__PACKAGE__->belongs_to( owner => 'Qublog::Schema::Result::User' );
__PACKAGE__->has_many( task_logs => 'Qublog::Schema::Result::TaskLog', 'comment' );
__PACKAGE__->has_many( comment_tags => 'Qublog::Schema::Result::CommentTag', 'comment' );
__PACKAGE__->many_to_many( tags => comment_tags => 'tag' );

=head1 METHODS

=head2 store_column

This hook clears the L</processed_name_cache> whenever the L</name> is set.

=cut

sub store_column {
    my ($self, $name, $value) = @_;

    # Clear the processed name cache if the name changes
    if ($name eq 'name') {
        $self->processed_name_cache(undef);
    }

    $self->next::method($name, $value);
}

=head2 as_journal_item

See L<Qublog::Schema::Role::Itemized>.

=cut

sub as_journal_item {
    my ($self, $options, $items) = @_;

    my $order_priority = eval {
          $self->journal_timer->id ? $self->journal_timer->start_time->epoch
        :                            $self->created_on->epoch;
    } || 0;
    $order_priority *= 10;
    $order_priority +=  5;

    my $name = 'Comment-'.$self->id;
    $items->{$name} = {
        id             => $self->id,
        name           => $name,
        order_priority => $order_priority,
        timestamp      => $self->created_on,
        record         => $self,
    };
}

=head2 list_journal_item_resultsets

See L<Qublog::Schema::Role::Itemized>.

=cut

sub list_journal_item_resultsets { };

=head1 AUTHOR

Andrew Sterling Hanenkamp, C<< <hanenkamp@cpan.org> >>

=head1 LICENSE

Qublog Personal/Professional Journaling
Copyright (C) 2009  Andrew Sterling Hanenkamp

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
