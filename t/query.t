#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';
use ok 'URI::Web::Test';

my $root = URI::Web::Test->ROOT;

is($root->QUERY({ foo => { bar => 1 }}),
   "http://test.com/?foo.bar=1",
   "single-level hash");

is($root->QUERY({ foo => { bar => 1, baz => [ 2, 3 ] }}),
   "http://test.com/?foo.baz.0=2&foo.baz.1=3&foo.bar=1",
   "hash and array");
