#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URIx::Site' );
}

diag( "Testing URIx::Site $URIx::Site::VERSION, Perl $], $^X" );
