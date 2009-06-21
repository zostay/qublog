package Qublog::Filter::SaltHash;

use warnings;
use strict;

use base qw|Jifty::DBI::Filter|;
use Digest;

=head1 NAME

Qublog::Filter::SaltHash - salts and hashes a value before storing it

=head1 DESCRIPTION

This class was copied and modified from L<Jifty::DBI::Filter::SaltHash>. It uses
a slightly different crypt algorithm than that class though. It is pretty heavily
modified to make it a little easier to work with.

This filter will generate a random 4-byte salt, and then digest the given
value with the salt appended to the value. It will store the hash and
the salt in the database, and return a data structure that contains
both on decode. The salt and hash are stored in hexadecimal in the
database, so that you can put them in a text field.

This filter is intended for storing passwords in a database.

=head2 encode

Generate a random 4-byte salt, digest the value with the salt appended to it,
and store both in the database.

=cut

sub encode {
    my $self = shift;
    my $value_ref = $self->value_ref;

    return unless defined $$value_ref;

    if (eval { $$value_ref->isa('Qublog::Filter::SaltHash::Value') }) {
        $$value_ref = "$$value_ref";
    }

    else {
        my $value = Qublog::Filter::SaltHash::Value->new( encode => $$value_ref );
        $$value_ref = "$value";
    }

    return 1;
}

=head2 decode

Returns the decoded value. Even though the value itself is a salted-hashed
string, you can compare a plain scalar to it to determine if they are equal.
This will DoTheRightThing(tm).

=cut

sub decode {
    my $self = shift;
    my $value_ref = $self->value_ref;

    return unless $$value_ref;

    if (eval { $$value_ref->isa('Qublog::Filter::SaltHash::Value') }) {
        return 1;
    }
    else {
        my $value = Qublog::Filter::SaltHash::Value->new( decode => $$value_ref );
        $$value_ref = $value;
    }

    return 1;
}

=head1 ENCODING CLASS

The password is encoded into an internal encoding class that has a few methods
on it. However, it's use should be more or less transparent and it's methods are
for internal use only at this time.

=cut

{
    package Qublog::Filter::SaltHash::Value;

    use overload 
        'eq' => \&equal_to,
        '""' => \&stringify,
        ;

    sub new {
        my ($class, $action, $value) = @_;

        if ($action eq 'encode') {
            $value = $class->digest($value);
        }

        bless \$value, $class;
    }

    sub generate_salt {
        my $salt;
        $salt .= unpack('H2', chr(int rand(255))) for(1..4);
        return $salt;
    }

    sub equal_to {
        my ($self, $value) = @_;

        if (eval { $value->isa('Qublog::Filter::SaltHash::Value') }) {
            return $$self eq $$value;
        }

        else {
            return $$self eq $self->digest("$value", $self->salt);
        }
    }

    sub stringify {
        my $self = shift;
        return $$self;
    }

    sub value_and_salt {
        my ($self, $value) = shift;
        $value ||= $$self;
        return [reverse unpack("A8A*", $value)];
    }

    sub value { return shift->value_and_salt->[0] }
    sub salt  { return shift->value_and_salt->[1] }

    sub digest {
        my ($self, $value, $salt) = @_;
        $salt ||= $self->generate_salt;

        my $digest_type = Jifty->config->app('salt_hash')->{digest} || 'MD5';
        my $digest_args = Jifty->config->app('salt_hash')->{args}   || [];
        my $digest = Digest->new($digest_type, @{ $digest_args });
        $digest->add($value);
        $digest->add($salt);

        return $salt . $digest->b64digest;
    }
}

=head1 SEE ALSO

L<Jifty::DBI::Filter>, L<Digest::MD5>

=head1 AUTHOR

This code was originally taken from the L<Jifty::DBI::Filter::SaltHash> module and modified to better suit the needs of Qublog.

=cut

1;
