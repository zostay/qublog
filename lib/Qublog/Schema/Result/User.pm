package Qublog::Schema::Result::User;
use Moose;
extends qw( Qublog::Schema::Result );

use DateTime::TimeZone;
use Digest;

=head1 NAME

Qublog::Schema::Result::User - the model for user accounts

=head1 DESCRIPTION

User accounts go here.

=head1 SCHEMA

=haed2 id

The autogenerated ID column.

=head2 name

The login name of the user. This is the unique key.

=head2 email

The email address of the user.

=head2 email_verified

A boolean value telling that the email address has been verified.

=head2 password

The salted password.

=head2 time_zone

The L<DateTime::TimeZone> selected the user.

=head2 agreed_to_terms_md5

The MD5 sum of the terms the last user agreed to.

=cut

__PACKAGE__->load_components(qw( Core ));
__PACKAGE__->table('users');
__PACKAGE__->add_columns(
    id             => { data_type => 'int' },
    name           => { data_type => 'text' },
    email          => { data_type => 'text' },
    email_verified => { data_type => 'boolean' },
    password       => { data_type => 'text' },
    time_zone      => { data_type => 'text' },
    agreed_to_terms_md5 => { data_type => 'text' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(
    name => [ qw( name ) ],
);

__PACKAGE__->inflate_column(time_zone => {
    inflate => sub { DateTime::TimeZone->new( name => shift ) },
    deflate => sub { shift->name },
});

=head1 METHODS

=head2 generate_salt

Generate random salt to encode the password.

=cut

sub generate_salt {
    my $salt;
    $salt .= unpack('H2', chr(int rand(255))) for (1..4);
    return $salt;
}

=head2 digest

Given a password and salt, returns the encrypted password ready to store.

=cut

sub digest {
    my ($self, $password, $salt) = @_;
    $salt ||= $self->generate_salt;

    # TODO Make this configurable, make it so that each password remember what
    # it was last encrypted with.
    my $digest = Digest->new('SHA-512');
    $digest->add($password);
    $digest->add($salt);

    return $salt . $digest->b64digest;
}

=head2 salt

Extract the salt from the encrypted password.

=cut

sub salt {
    my $self = shift;
    my $password = $self->password;
    return unpack("A8", $password);
}

=head2 check_password

Check a cleartext password against the hashed one stored for the user.

=cut

sub check_password { 
    my ($self, $cleartext) = @_;
    my $salt = $self->salt;
    my $hashtext = $self->digest($cleartext, $salt);

    return $hashtext eq $self->password;
}

=head2 change_password

Modify the password to a new one based on a passed cleartext.

=cut

sub change_password {
    my ($self, $cleartext) = @_;
    $self->password($self->digest($cleartext));
}

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
