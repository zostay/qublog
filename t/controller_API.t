use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'Qublog::Server' }
BEGIN { use_ok 'Qublog::Server::Controller::API' }

ok( request('/api')->is_success, 'Request should succeed' );


