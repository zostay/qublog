use strict;
use warnings;

=head1 DESCRIPTION

Checks to make sure that things with ownership can't be seen by someone who is not the owner.

=cut

use lib 't/lib';
use List::Util qw( shuffle );
use Jifty::Test tests => 10;
use Qublog::Test;

my $owner_user   = test_current_user('owner');
my $current_user = test_current_user('other');

setup_test_user($current_user);

ok($owner_user->id, 'we have an owner user');
ok($current_user->id, 'we have a current user');
is($current_user->id, Jifty->web->current_user->id, 'current user is logged');

sub random_letter {
    my @letters = shuffle(' ', '0' .. '9', 'A' .. 'Z', 'a' .. 'z');
    return $letters[ int(rand(scalar(@letters))) ];
}

sub random_value {
    return join '', map { random_letter() } 0 .. int(rand(40) + 10);
}

my %models = (
    Comment => [ qw( name ) ],
);

while (my ($name, $required) = each %models) {
    my $class = 'Qublog::Model::' . $name;

    my %params = map { $_ => random_value() } @$required;
    $params{owner} = $owner_user->id;

    my $obj_id;
    {
        my $obj = $class->new( current_user => $owner_user->id );
        $obj->create( %params );

        ok($obj->id, 'got an object');
        is($obj->owner->id, $owner_user->id, 'owner is correct');
        isnt($obj->owner->id, $current_user->id, 'owner is not current user');

        ok($owner_user->owns($obj), 'owner user owns object');
        ok(!$current_user->owns($obj), 'current user does not own object');

        $obj_id = $obj->id;
    }

    {
        my $obj = $class->new;
        my $error = $obj->load($obj_id);

        is($obj->id, $obj_id, 'direct load of object worked');
        for my $col (@{ $required }) {
            is($obj->$col, undef, "access to $col column is correctly forbidden");
        }
    }
}
