package URI::Site::Test;

use URI::Site::Util '-all';
use URI::Site -base => {
  path => '',
  map  => [
    qw(base),
    sub => handler 'Sub',
  ],
};

1;
