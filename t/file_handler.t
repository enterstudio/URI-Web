#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';
use ok 'URI::Web::Test';

my $root = URI::Web::Test->ROOT;

is($root->html, "http://test.com/html/");
is($root->html("foo.html"), 'http://test.com/html/foo.html');

