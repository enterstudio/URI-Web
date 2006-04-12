package URI::Site::Test::Sub;

use URI::Site::Util '-all';
use URI::Site::Test -base => [
  qw(sub-base),
  subber => handler 'Subber',
];

1;
