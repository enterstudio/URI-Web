#!perl

use strict;
use warnings;

use lib 't/lib';
use Test::More 'no_plan';
use ok 'URI::Web::Test';

my $root = URI::Web::Test->ROOT;

my $easy = $root->easy;

is("$easy", "http://test.com/easy/");
is($easy->as->pie, "http://test.com/easy/as/pie/");

my $easier = $root->easier;

is("$easier", "http://test.com/easier/");
is($easier->than->that, "http://test.com/easier/than/that/");

my $easiest = $root->easiest;

is("$easiest", "http://test.com/easiest/");
is($easiest->of->all, "http://test.com/easiest/of/all/");

my $easysub = $root->sub->easy;
is("$easysub", "http://test.com/sub/easy/");

my $deep = $easysub->just->add->water->and->then->eat->it;
is($deep, "http://test.com/sub/easy/just/add/water/");
is($deep->WITH({ id => 5 }), "http://test.com/sub/5/easy/just/add/water/");
