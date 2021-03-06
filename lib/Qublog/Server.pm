package Qublog::Server;
use Moose;

use Catalyst::Runtime 5.80;

use Qublog::Dumper;

use Digest::MD5 qw( md5_hex );
use File::Slurp qw( read_file );
use Form::Factory;

use Qublog::DateTime;
use Qublog::Feature::Control::DateTime;
use Qublog::Feature::Control::TimeZone;
use Qublog::Types;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use parent qw/Catalyst/;
use Catalyst qw(
    -Debug
    ConfigLoader
    Static::Simple

    StackTrace

    Authentication

    Session
    Session::Store::FastMmap
    Session::State::Cookie
);
our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in qublog_server.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( 
    name         => 'Qublog::Server',
    default_view => 'TD',
);

# Start the application
__PACKAGE__->setup();


=head1 NAME

Qublog::Server - Catalyst based application

=head1 SYNOPSIS

    script/qublog_server_server.pl

=head1 DESCRIPTION

Qublog is a personal/professional logging application that runs in a web
browser. It allows you to keep your notes, organize your tasks, and track you
time on projects in the same place.

=head1 ATTRIBUTES

=head2 form_interface

This is the object used to render and process forms.

=cut

has _form_interface => (
    is        => 'ro',
    does      => 'Form::Factory::Interface',
    required  => 1,
    lazy      => 1,
    default   => sub { 
        Form::Factory->new_interface(HTML => {
            renderer => sub { Template::Declare::Tags::outs_raw(@_) },
            consumer => sub { $_[0]->params },
        });
    }
);

sub form_interface {
    my $c = shift;
    $c->_form_interface->stasher->stash_hash($c->session);
    return $c->_form_interface;
}

=head1 METHODS

=head2 action_form

Helper to get form objects to rendering and processing actions.

=cut

{
    my %action_form_type_prefixes = (
        schema => 'Qublog::Schema::Action::',
        server => 'Qublog::Server::Action::',
    );

    sub action_form {
        my ($c, $type, $name, $args) = @_;
        die "invalid action name $name" if $name =~ /[^\w:]/;

        my $class_name = $action_form_type_prefixes{$type};
        die "invalid action type $type" unless $class_name;
        $class_name .= $name;

        my %args = %{ $args || {} };
        if ($type eq 'schema') {
            $args{schema} = $c->model('DB')->schema;
        }
        elsif ($type eq 'server') {
            $args{c} = $c;
        }

        # Specially requested action attributes
        Class::MOP::load_class($class_name);
        my $meta = Class::MOP::class_of($class_name);
        $args{journal_session} = $c->current_journal_session
            if $meta->does_role('Qublog::Action::Role::WantsJournalSession');
        $args{time_zone} = $c->time_zone
            if $meta->does_role('Qublog::Action::Role::WantsTimeZone');
        $args{today} = $c->today
            if $meta->does_role('Qublog::Action::Role::WantsToday');
        $args{current_user} = $c->user->get_object
            if $meta->does_role('Qublog::Action::Role::WantsCurrentUser');

        # This forces me to make my actions secure
        die "will not run insecure actions"
            unless $meta->does_role('Qublog::Action::Role::Secure');

        $c->form_interface->new_action($class_name => \%args);
    }
}

=head2 current_journal_session

Finds a journal session for the user. Returns C<undef> if there are no available running sessions.

=cut

sub current_journal_session {
    my ($c, $date) = @_;

    $date //= $c->today;
    my $sessions = $c->model('DB::JournalSession')
        ->search({ owner => $c->user->get_object->id }, 
                 { order_by => { -desc => 'start_time' } })
        ->search_by_day($date);

    # See if a session has been picked
    if ($c->session->{current_session_id}) {
        SESSION: 
        for my $session ($sessions->all) {
            if ($session->id == $c->session->{current_session_id}) {
                $c->stash->{session} = $session;
                last SESSION;
            }
        }
    }

    # If one isn't already selected today, pick something
    unless ($c->stash->{session}) {
        delete $c->session->{current_session_id};
        $c->stash->{session} = $sessions->first;
    }

}

=head2 result_to_messages

Convert form results into messages.

=cut

sub result_to_messages {
    my ($c, $result) = @_;

    for my $message (@{ $result->messages }) {
        next if $message->is_tied_to_field;

        push @{ $c->flash->{messages} }, {
            type    => $message->type,
            message => $message->message,
        };
    }
}

=head2 field_defaults

  my $fields = $c->field_defaults({
      name    => 'frobincate',
      scuffer => undef,
  });

Returns a hash reference of fields to use in populating an HTML form. Only the
keys named in the input hash will be returned (and will always be returned, even
if the value is C<undef>). Each field will be loaded from the current form
submitted with the request, the last value stored in flash, or the default value
passed, in that order. The return hash reference is stored in the flash.

=cut

sub field_defaults {
    my ($c, $fields) = @_;

    for my $key (keys %$fields) {
        $fields->{ $key } 
            = $c->request->params->{ $key } ? $c->request->params->{ $key }
            : $c->flash->{fields}{ $key }   ? $c->flash->{fields}{ $key }
            :                                 $fields->{ $key }
            ;
    }

    return $c->flash->{fields} = $fields;
}

=head2 add_style

  $c->add_style( file => 'journal');
  $c->add_style( code => 'body { background-color: blue }' );

Add a stylesheet to the header of the current page. The first form adds:

  /static/style/journal.css

into the head tag while the second adds the literal code in a style-tag inside
of the head.

=cut

sub add_style {
    my ($c, $type, $code) = @_;
    push @{ $c->stash->{style} }, Qublog::Server::Link->new(
        $type => $code,
        type  => 'style',
    );
}

=head2 add_script

  $c->add_script( file => 'journal' );
  $c->add_script( code => '$("body").css("background-color", "blue")' );

Add a script to the header of the current page. The first form adds:

  /static/script/journal.js

into the head tag while the second adds the literal code in a script-tag inside
of the head.

=cut

sub add_script {
    my ($c, $type, $code) = @_;
    push @{ $c->stash->{script} }, Qublog::Server::Link->new(
        $type => $code,
        type  => 'script',
    );
}

=head2 time_zone

  my $time_zone = $c->time_zone;

Returns the best L<DateTime::TimeZone> to use on the current request. If a user
is currently logged, the users's preferred time zone will be chosen. If no user
is logged, then the site default will be used instead.

=cut

sub time_zone {
    my $c = shift;

    if ($c->user_exists) {
        return $c->user->get_object->time_zone;
    }

    return DateTime::TimeZone->new( name => $c->config->{'time_zone'} );
}

=head2 now

  my $now = $c->now;

Returns the current time with the time zone set to the time zone returned by
L</time_zone>.

=cut

sub now {
    my $c = shift;
    return Qublog::DateTime->now->set_time_zone( $c->time_zone );
}

=head2 today

  my $today = $c->today;

Returns the current time from L</now>, but with the time set to 0.

=cut

sub today {
    my $c = shift;
    return $c->now->truncate( to => 'day' );
}

=head2 current_terms_md5

  my $md5_sum = $c->current_terms_md5;

Loads the license file stored in the

  Qublog::Terms -> file

configuration setting and performs an MD5 checksum on it. It returns the
hexidecimal version of that sum to be used in determining whether or not the
user has agreed to the latest terms or not.

=cut

sub current_terms_md5 {
    my $c = shift;

    my $config = $c->config->{'Qublog::Terms'};
    my $license = $config->{file};

    my $license_path = $c->path_to('root', 'content', $license);
    return unless -f $license_path;

    return md5_hex(read_file("$license_path"));
}

=head1 SEE ALSO

L<Qublog::Server::Controller::Root>, L<Catalyst>

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
