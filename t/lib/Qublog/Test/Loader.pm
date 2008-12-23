use strict;
use warnings;

package Qublog::Test::Loader;
use base 'Test::Class::Load';

our $NOT_A_TEST = 1;

sub is_test_class {
    my $class = shift;
    my ($file, $dir) = @_;

    return unless $class->SUPER::is_test_class(@_);

    open my $pm, $file or die "cannot open $file: $!";
    PM: while (<$pm>) {
        if (/^(?:our)?\s*$NOT_A_TEST\s*=\s*([^;]+);/) {
            return if eval $1;
            die $@ if "cannot determine if $file is a test: $@";
            last PM;
        }
    }

    return 1;
}

1;
