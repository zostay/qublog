package Qublog::Schema::Result::Tag;
use Moose;
extends qw( Qublog::Schema::Result );
with qw( Qublog::Schema::Role::Itemized );

use Number::RecordLocator;

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('tags');
__PACKAGE__->add_columns(
    id   => { data_type => 'int' },
    name => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(
    name => [ qw( name ) ],
);
__PACKAGE__->has_many( task_tags => 'Qublog::Schema::Result::TaskTag', 'tag' );
__PACKAGE__->has_many( comment_tags => 'Qublog::Schema::Result::CommentTag', 'tag' );
__PACKAGE__->has_many( journal_entry_tags => 'Qublog::Schema::Result::JournalEntryTag', 'tag' );
__PACKAGE__->many_to_many( tasks => task_tags => 'task' );
__PACKAGE__->many_to_many( comments => comment_tags => 'comment' );
__PACKAGE__->many_to_many( journal_entries => journal_entry_tags => 'journal_entry' );

my $record_locator;
has record_locator => (
    is        => 'ro',
    isa       => 'Number::RecordLocator',
    required  => 1,
    lazy      => 1,
    default   => sub { $record_locator ||= Number::RecordLocator->new },
);

sub new {
    my ($class, $args) = @_;

    my $autotag = delete $args->{autotag};
    $args->{name} = '-' if $autotag;

    my $self = $class->next::method($args);

    my $schema = $self->result_source->schema;
    my $tags   = $schema->resultset('Tag');

    # TODO Hard coded sequence ID 1 is probably bad
    if ($autotag and $self) {
        $schema->txn_do(sub {
            my $sequence = $schema->resultset('Sequence')->find(1);
            
            my $autoname;
            $sequence->next_value(sub {
                $autoname = $self->record_locator->encode($_[0]);
                return 0 if ($tags->find({ name => $autoname }));
                return 1;
            });
            $sequence->update;

            $self->name($autoname);
        });
    }

    return $self;
}

sub as_journal_item { }

sub list_journal_item_resultsets {
    my ($self, $c) = @_;
    
    my @result_sets;
    push @result_sets, scalar $self->comments;
    push @result_sets, scalar $self->tasks;
    push @result_sets, scalar $self->journal_entries;

    return [ grep { $_ } @result_sets ];
}

1;
