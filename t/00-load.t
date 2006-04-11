#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'URI::Site' );
}

diag( "Testing URI::Site $URI::Site::VERSION, Perl $], $^X" );
