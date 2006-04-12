#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More 'no_plan';
use ok 'URI::Site::Test';

isa_ok(
  URI::Site::Test->sub->subber->subbest, 'URI',
  "deep leaf"
);

is(
  URI::Site::Test->sub->subber->subbest->path,
  '/sub/subber/subbest',
  "deep leaf path",
);

