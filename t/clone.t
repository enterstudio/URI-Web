#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';
use URI::Web::Test;

my $web = URI::Web::Test->ROOT->args({ foo => 1, bar => 2 })
  ->QUERY({ x => 1 });

my $clone = $web->WITH({
  foo => 3, bar => 4, baz => 5,
  HOST => "clone.com",
  PATH => '/clone-args',
  __query => { y => 2 },
});

is $clone->__args->{foo}, 3;
is $web->__args->{foo}, 1, "clone does not affect original __args";
is $clone->__query->{y}, 2;
is $web->__query->{y}, undef, "clone does not affect original __query";

