package URI::Site::Util;

use strict;
use warnings;

use Params::Util qw(_STRING _HASH);
use Sub::Exporter -setup => {
  exports => [qw(handler class permissive)],
};

=head1 NAME

URI::Site::Util

=head1 DESCRIPTION

=head1 FUNCTIONS

All functions are exportable.

=head2 handler

=cut

sub _die {
  require Carp::Clan;
  Carp::Clan->import('croak');
  croak(@_);
 }

sub _loaded {
  no strict 'refs';
  return defined %{shift() . '::'};
}

sub handler ($) {
  my $class = _STRING(shift) || 
    _die "argument to handler() must be class name or stub";

  $class = caller() . "::$class" unless $class =~ s/^\+//;

  return sub {
    my $obj = shift;
    unless (_loaded($class)) {
      warn "loading $class\n";
      eval "require $class";
      die $@ if $@;
    }

    return $class->new({
      parent => $obj,
      @_,
    });
  };
}

=head2 class

=cut

my $I = 0;
sub _subclass {
  my ($base, $prefix) = @_;
  my $subclass = sprintf("%s::%s_%08x", $base, $prefix, $I++);
  no strict 'refs';
  @{$subclass . '::ISA'} = $base;
  return $subclass;
}

sub class ($) {
  my $site = _HASH(shift) || _die "argument to class() must be hashref";
  my $caller = _STRING(shift) || caller;

  my $class = _subclass($caller, 'site');
  $class->setup_site($site);
  return $class;
}

=head2 permissive

=cut

sub permissive () {
  # deliberately avoid prototype
  my $class = &class({ permissive => 1 }, scalar caller);
  eval sprintf <<'', $class;
package %s;
require URI::Site::Permissive;
URI::Site::Permissive->import('-mixin');

  die $@ if $@;

  return handler $class;
}

1;
