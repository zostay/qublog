package Qublog::Server::Action::GotoJournalDate;
use Form::Factory::Processor;

has c => (
    is        => 'ro',
    isa       => 'Qublog::Server',
    required  => 1,
);

has_control date => (
    control   => 'text',
    options   => {
        default_value => deferred_value { 
            my $self = shift;
            Qublog::DateTime->format_human_date(
                $self->c->today, 
                $self->c->time_zone
            );
        },
    },
    features  => {
        required => 1,
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
        $self->c->uri_for('/journal/day', $self->date)
    );
}

1;
