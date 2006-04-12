package URI::Site::Test::Sub;

use URI::Site::Util '-all';
use URI::Site -base => {
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
