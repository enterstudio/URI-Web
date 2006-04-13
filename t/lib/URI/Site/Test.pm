package URI::Web::Test;

use URI::Web::Util '-all';
use URI::Web -base => {
  host  => 'test.com',
  path  => '',
  map   => [
    qw(base),
    sub => handler 'Sub',
  ],
};

1;
