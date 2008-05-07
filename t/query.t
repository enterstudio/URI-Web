#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';
use ok 'URI::Web::Test';
use Data::Dumper;

my $root = URI::Web::Test->ROOT;

sub is_query {
  my ($web, $data, $label) = @_;
  is_deeply(
    { $web->URI->query_form },
    $data,
    $label,
  );
}

is_query $root->QUERY({ foo => { bar => 1 }}),
  { 'foo.bar' => 1 }, "single-level hash";

is_query $root->QUERY({ foo => { bar => 1, baz => [ 2, 3 ] }}),
  { 'foo.bar' => 1, 'foo.baz.0' => 2, 'foo.baz.1' => 3 }, 
  "hash and array";

is_query $root->QUERY({ foo => { bar => 1 }, _LITERAL => { 'foo.baz' => 2 } }),
  { 'foo.bar' => 1, 'foo.baz' => 2 },
  "literal with nesting";

my $test = $root->QUERY({ a => [1] });
is_query $test, { 'a.0' => 1 }, "flattened array";
$test = $test->QUERY_PLUS({ b => 2 });
is_query $test, { 'a.0' => 1, b => 2 }, "QUERY_PLUS did not munge a.0"
  or diag Dumper({ $test->URI->query_form });
