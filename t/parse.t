#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';
use ok 'URI::Web::Test';

sub is_url {
  my ($url, $obj) = @_;
  is(
    URI::Web::Test->PARSE($url),
    $obj,
  );
}

my $root = URI::Web::Test->ROOT;
is_url("http://test.com/", $root);

is_url("http://subtest.com/sub/", $root->sub);
is_url("http://subtest.com/sub/17/", $root->sub({ id => 17 }));

is_url("http://subtest.com/sub/subber", $root->sub->subber);
is_url("http://subtest.com/sub/17/subber",
       $root->sub->subber->WITH({ id => 17 }));

$ENV{SITE_subtest_com_sub_PATH} = '/';
is($root->sub, "http://subtest.com/");
is($root->sub({ id => 17 }), "http://subtest.com/17/");

TODO: {
  local $TODO = "env path changing";
  is_url("http://subtest.com/17/", $root->sub({ id => 17 }));
}
