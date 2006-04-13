package URI::Web::Permissive;

use strict;
use warnings;

use URI::Web::Util '-all';

use Sub::Exporter -setup => {
  exports => [ 'AUTOLOAD' ],
  groups => { mixin => [qw(-all)] },
};

our $AUTOLOAD;
sub AUTOLOAD {
  my $self = shift;
  (my $meth = $AUTOLOAD) =~ s/.*:://;
  return if $meth eq 'DESTROY';

  my $clone = $self->_clone;
  $clone->__parent($self);
  $clone->__path($meth);

  return $clone;
}

1;
