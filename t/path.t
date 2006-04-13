#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More 'no_plan';
use ok 'URI::Site::Test';

my $root = URI::Site::Test->root;

isa_ok($root, 'URI::Site::Test');
isa_ok($root, 'URI::Site');
isa_ok($root, 'URI::Site::Node');
is("$root", 'http://test.com/', 'root uri');

my $sub = $root->sub;
isa_ok($sub, 'URI::Site');
is("$sub", "http://test.com/sub/", "sub uri (no args)");

$sub = $root->sub({ id => 17 });
is("$sub", "http://test.com/sub/17/", "sub uri (args)");

my $subber = $sub->subber;
is("$subber", "http://test.com/sub/17/subber/", "subber uri");

my $subbest = $sub->subber->subbest;
isa_ok($subbest, 'URI::Site::Leaf');
is("$subbest", 'http://test.com/sub/17/subber/subbest', "subbest leaf");

is($sub->WITH({ id => 2 }), "http://test.com/sub/2/", "sub uri (with)");
is($sub, "http://test.com/sub/17/", "sub uri (unchanged)");

is($subber->WITH({ id => 2 }),  "http://test.com/sub/2/subber/",
   "subber uri (with)");
is($subber, 'http://test.com/sub/17/subber/', "subber (unchanged)");

is($subbest->WITH({ id => 3 }), "http://test.com/sub/3/subber/subbest",
   "subbest uri (with)");
is($subbest, 'http://test.com/sub/17/subber/subbest', 'subbest (unchanged)');

my $page5 = $root->QUERY({ page => 5 });
is($page5, "http://test.com/?page=5", 'root query');
is($page5->QUERY_PLUS({ color => 'red' }), "http://test.com/?page=5&color=red", 'root query plus');

is($root->WITH({ PORT => 8080 }), "http://test.com:8080/", "WITH PORT");
is($sub->WITH({ HOST => 'try.com' }), "http://try.com/sub/17/", "WITH HOST");
is($sub->WITH({ SCHEME => 'https' }), "https://test.com/sub/17/", "WITH SCHEME (branch)");
is($subbest->WITH({ SCHEME => 'https' }),
   "https://test.com/sub/17/subber/subbest", "WITH SCHEME (leaf)");

my $templ = <<'';
[%- root.QUERY(color = 'red') -%]

use Template;
my $out;
Template->new->process(\$templ, { root => $root }, \$out);
is($out, $root->QUERY({ color => 'red' }), "template");
