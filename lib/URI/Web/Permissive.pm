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

=head1 NAME

URI::Web::Permissive

=head1 DESCRIPTION

URI::Web::Permissive provides an AUTOLOAD method to classes
that import it.  This method allows generation of any url
underneath the URI::Web object's namespace.

=head1 METHODS

=head2 AUTOLOAD

=cut

1;
