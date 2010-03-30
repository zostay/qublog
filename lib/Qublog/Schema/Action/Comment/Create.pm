package Qublog::Schema::Action::Comment::Create;
use Form::Factory::Processor;

extends qw( Qublog::Schema::Action::Comment::Store );
with qw( 
    Qublog::Schema::Action::Role::Lookup::New 
    Qublog::Action::Role::Secure::CheckOwner
);

has journal_day => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::JournalDay',
    required  => 1,
    traits    => [ 'Model::Column' ],
);

has journal_timer => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::JournalTimer',
    required  => 1,
    traits    => [ 'Model::Column' ],
);

has owner => (
    is        => 'ro',
    isa       => 'Qublog::Schema::Result::User',
    required  => 1,
    traits    => [ 'Model::Column' ],
);

has created_on => (
    is        => 'ro',
    isa       => 'DateTime::DateTime',
    required  => 1,
    traits    => [ 'Model::Column' ],
);

after may_run => sub {
    my $self = shift;

    my $journal_timer = $self->schema->resultset('JournalTimer')->find(
        $self->journal_timer
    );
    return unless $journal_timer;

    my $journal_entry = $journal_timer->journal_entry;
    unless ($self->owner->id == $journal_entry->owner->id) {
        $self->error('you cannot create a comment on an entry for someone else');
        $self->is_valid(0);
    }
};

1;
