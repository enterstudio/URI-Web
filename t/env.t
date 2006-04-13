#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';
use ok 'URI::Site::Test';

my $root = URI::Site::Test->root;

my $subber = $root->sub->subber;

$ENV{SITE_test_com_sub_subber_PATH} = 'mayo';

is("$subber", "http://test.com/sub/mayo/");
is($subber->WITH({ id => 7 }), "http://test.com/sub/7/mayo/");

$ENV{SITE_test_com_sub_PATH} = 'hoagie';

my $sub = $root->sub;

is("$sub", "http://test.com/hoagie/");
is("$subber", "http://test.com/hoagie/mayo/");

$ENV{SITE_test_com_sub_HOST} = 'try.com';
$sub = $sub->WITH({ id => 5 });
$subber = $sub->subber;

is("$root", "http://test.com/");
is("$sub", "http://try.com/hoagie/5/");
is("$subber", "http://try.com/hoagie/5/mayo/");

$ENV{SITE_test_com_PORT} = 8080;

is("$root", "http://test.com:8080/");
is("$sub", "http://try.com:8080/hoagie/5/");
