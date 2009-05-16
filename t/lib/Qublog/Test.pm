use strict;
use warnings;

package Qublog::Test;

require Exporter;
our @ISA = qw( Exporter );

our @EXPORT = qw( 
    superuser 
    test_user 
    test_current_user 
    setup_test_user 
);

=head1 NAME

Qublog::Test - Some helps for testing

=head1 SYNOPSIS

  use strict;
  use warnings;

  use lib 't/lib';
  use Jifty::Test tests => 42;
  use Qublog::Test;

  setup_test_user;

  # run your tests

=head1 DESCRIPTION

=head1 METHODS

=head2 superuser

Shortcut to create a super user for use with testing.

=cut

sub superuser() {
    return Qublog::CurrentUser->superuser;
}

=head2 test_user

This method creates an account for use with testing. It takes two optional arguments. The first is the C<name> of the user, which defaults to "test_user". The second is the C<password> of the user, which defaults to "secret".

=cut

sub test_user(;$$) {
    my ($name, $password) = @_;
    $name     ||= 'test_user';
    $password ||= 'secret';

    my $user = Qublog::Model::User->new( current_user => superuser );
    $user->load_or_create( name => $name, password => $password );

    return $user;
} 

=head2 test_current_user

This method creates a test current user. With no arguments or with a given login name and password, it will use L</test_user> to create a new user account and then use that for the current user returned. If a L<Qublog::Model::User> object is given, it will use that as the user.

=cut

sub test_current_user(;$$) {
    my ($name, $password) = @_;
    my $user = ref $name ? $name : test_user($name, $password);

    return Qublog::CurrentUser->new( id => $user->id );
}

=head1 setup_test_user

This method creates a test user (or uses the same arguments as L</test_current_user> to get one). It then calls C<< Jifty::Test->web >> and sets C<< Jifty->web->current_user >> to the new current user object.

=cut

sub setup_test_user(;$$) {
    my $current_user = test_current_user($_[0], $_[1]);

    Jifty::Test->web;
    Jifty->web->current_user($current_user);
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Andrew Sterling Hanenkamp.

This is free software. You may modify and distribute it under the terms of the Artistic 2.0 license.

=cut

1;
