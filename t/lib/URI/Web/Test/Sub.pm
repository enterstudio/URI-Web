package URI::Web::Test::Sub;

use URI::Web::Util '-all';
use URI::Web -base => {
  host => 'subtest.com',
  map  => [
    qw(sub-base),
    subber => [
      qw(subbest),
    ],
    easy => permissive,
    elsewhere => \"/else/where",
    overthere => \"/over/there.html",
    legacy    => handler class {
      path => "/old",
      env  => "test_com_legacy",
    },
  ],
  path_args => [ 'id' ],
};

1;
