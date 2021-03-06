#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';
use ok 'URI::Web::Test';

my $root = URI::Web::Test->ROOT;

my $subber = $root->sub->subber;

my $old = $root->sub->legacy;
is("$old", "http://subtest.com/old/");

$ENV{SITE_test_com_legacy_HOST} = "test.test.com";
is("$old", "http://test.test.com/old/");

$ENV{SITE_subtest_com_sub_subber_PATH} = 'mayo';

is("$subber", "http://subtest.com/sub/mayo/");
is($subber->WITH({ id => 7 }), "http://subtest.com/sub/7/mayo/");

$ENV{SITE_subtest_com_sub_PATH} = 'hoagie';

my $sub = $root->sub;

is("$sub", "http://subtest.com/hoagie/");
is("$subber", "http://subtest.com/hoagie/mayo/");

$ENV{SITE_subtest_com_sub_HOST} = 'try.com';
$sub = $sub->WITH({ id => 5 });
$subber = $sub->subber;

is("$root", "http://test.com/");
is("$sub", "http://try.com/hoagie/5/");
is("$subber", "http://try.com/hoagie/5/mayo/");

$ENV{SITE_test_com_PORT} = 8080;

is("$root", "http://test.com:8080/");
is("$sub", "http://try.com:8080/hoagie/5/");

$ENV{SITE_subtest_com_sub_SCHEME} = 'https';

is("$sub", "https://try.com:8080/hoagie/5/");

TODO: {
  local $TODO = "this does not yet 'just work' with the port setting, above";
  is("$sub", "https://try.com/hoagie/5/");
}

