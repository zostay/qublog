package Qublog::Schema::Result::User;
use Moose;
extends qw( Qublog::Schema::Result );

use DateTime::TimeZone;
use Digest;

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

sub generate_salt {
    my $salt;
    $salt .= unpack('H2', chr(int rand(255))) for (1..4);
    return $salt;
}

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

sub salt {
    my $self = shift;
    my $password = $self->password;
    return unpack("A8", $password);
}

sub check_password { 
    my ($self, $cleartext) = @_;
    my $salt = $self->salt;
    my $hashtext = $self->digest($cleartext, $salt);

    return $hashtext eq $self->password;
}

sub change_password {
    my ($self, $cleartext) = @_;
    $self->password($self->digest($cleartext));
}

1;
