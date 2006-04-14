package URI::Web::Test;

use URI::Web::Util '-all';
use URI::Web -base => {
  host  => 'test.com',
  path  => '',
  map   => [
    qw(base),
    sub       => handler 'Sub',
    easy      => handler 'Easy',
    easier    => handler class { permissive => 1 },
    easiest   => permissive,
  ],
};

1;
