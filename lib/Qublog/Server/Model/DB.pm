package Qublog::Server::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'Qublog::Schema',
    
    
);

=head1 NAME

Qublog::Server::Model::DB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<Qublog::Server>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Qublog::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.28

=head1 AUTHOR

Andrew Sterling Hanenkamp

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;