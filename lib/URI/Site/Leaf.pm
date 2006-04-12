package URI::Site::Leaf;

use strict;
use warnings;

use base qw(URI::Site::Object);

sub _canon_path {
  my $path = shift->SUPER::_canon_path(shift);
  $path =~ s!/+$!!;
  return $path;
}

# leaves should never be handling variables (really?)
# XXX this seems a little weird, but we can work around it if we really need to
my $EMPTY = {};
sub _site { $EMPTY }; 

1;
