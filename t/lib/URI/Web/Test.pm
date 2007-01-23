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
    args      => handler 'Args',
    file_handler('html'),
  ],
};

package URI::Web::Test::Args;

use URI::Web -base => {
  path_args => [
    qw(foo bar),
    baz =>  sub { defined($_[0]) && length($_[0]) ? "baz/$_[0]"  : "" },
    quux => sub { defined($_[0]) && length($_[0]) ? "quux=$_[0]" : "" },
  ],
};

1;
