use strict;
use warnings;

package Qublog::Model::Tag;
use Jifty::DBI::Schema;

=head1 NAME

Qublog::Model::Tag - tag tasks and comments

=head1 SYNOPSIS

  # Please add one...

=head1 DESCRIPTION

Tags can be attached to tasks and comments and are also used to associated extra metadata with tasks and comments.

=head1 SCHEMA

=cut

use Qublog::Record schema {

};

use Qublog::Mixin::Model::Nicknamed;

=head1 METHODS

=head2 since

This has been part of the application since database version 0.3.1.

=cut

sub since { '0.3.1' }

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

=cut

1;

