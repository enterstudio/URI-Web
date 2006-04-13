#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URI::Web' );
}

diag( "Testing URI::Web $URI::Web::VERSION, Perl $], $^X" );
