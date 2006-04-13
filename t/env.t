#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';
use ok 'URI::Site::Test';

my $root = URI::Site::Test->root;

my $sub = $root->sub;

$ENV{SITE_test_com_sub_PATH} = '/hoagie';

is("$sub", "http://test.com/hoagie/");
is($sub->WITH({ id => 7 }), "http://test.com/hoagie/7/");
