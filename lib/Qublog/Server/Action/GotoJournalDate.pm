package Qublog::Server::Action::GotoJournalDate;
use Form::Factory::Processor;

with qw(
    Qublog::Action::Role::WantsTimeZone
    Qublog::Action::Role::WantsCurrentUser
    Qublog::Action::Role::Secure::AlwaysRun
);

has c => (
    is        => 'ro',
    isa       => 'Qublog::Server',
    required  => 1,
);

has_control date => (
    is        => 'rw',
    isa       => 'DateTime',

    control   => 'text',

    features  => {
        fill_on_assignment => 1,
        date_time => {
            parse_method  => 'parse_human_date',
            format_method => 'format_iso_date',
        },
        required  => 1,
        trim      => 1,
    },
);

has_checker parseable_date => sub {
    my $self = shift;

    my $date = Qublog::DateTime->parse_human_date(
        $self->controls->{date}->current_value,
        $self->c->time_zone,
    );

    unless ($date) {
        $self->result->field_error(
            date => 'cannot understand that date',
        );
        $self->result->is_valid(0);
    }
};

sub run {
    my $self = shift;

    $self->c->response->redirect(
        $self->c->uri_for('/journal/day', $self->date->ymd)
    );
}

1;
