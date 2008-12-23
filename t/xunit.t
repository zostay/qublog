#!/usr/bin/perl
use strict;
use warnings;

use lib 't/lib';
use Qublog::Test::Loader qw( t/lib );

Test::Class->runtests;
