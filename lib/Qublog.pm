use strict;
use warnings;

package Qublog;
use 5.008;

our $VERSION = '0.01';

=head1 NAME

Qublog - An application to help you journal your work

=head1 SYNOPSIS

  # Hopefully, this will be easier to use in the future. You will need Perl 5.8
  # to get started. This has, as of this writing, only been tested on Mac OS X
  # 10.5 (Leopard).

  # Run
  bin/jifty server

  # Open your web browser and go to: http://localhost:8888/

=cut

sub start {
    Jifty->web->add_javascript(qw(
        jquery.autogrow.js
        ui/ui.core.js
        ui/ui.draggable.js
        ui/ui.droppable.js
        ui/effects.core.js
        ui/effects.highlight.js
        ui/effects.shake.js
        journal.js
        tasks.js
    ));
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< <hanenkamp@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Andrew Sterling Hanenkamp.

This is free software. You may modify and distribute it under the terms of the Artistic 2.0 license.

=cut

1;
