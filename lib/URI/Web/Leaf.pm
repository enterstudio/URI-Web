package URI::Web::Leaf;

use strict;
use warnings;

use base qw(URI::Web::Node);

sub _canon_path {
  my $path = shift->SUPER::_canon_path(shift);
  $path =~ s!/+$!!;
  return $path;
}

=head1 NAME

URI::Web::Leaf

=head1 DESCRIPTION

=head1 METHODS

=head2 setup_site

=cut

sub setup_site {
  my $class = shift;
  $class->_site(@_);
}

__PACKAGE__->setup_site({});

1;
