package URI::Site::Test;

use URI::Site::Util '-all';
use URI::Site -base => {
  host  => 'test.com',
  path  => '',
  map   => [
    qw(base),
    sub => handler 'Sub',
  ],
};

1;
