package URI::Web::Test::Sub;

use URI::Web::Util '-all';
use URI::Web -base => {
  map => [
    qw(sub-base),
    subber => [
      qw(subbest),
    ],
  ],
  path_args => [
    qw(id),
  ],
};

1;