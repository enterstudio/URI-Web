package URI::Web::Util;

use strict;
use warnings;

use Package::Generator;
use Params::Util qw(_STRING _HASH);
use Sub::Exporter -setup => {
  exports => [qw(_die _catpath handler class permissive)],
};

=head1 NAME

URI::Web::Util

=head1 DESCRIPTION

=head1 FUNCTIONS

All functions are exportable.

=cut

my $CLASS = 'URI::Web';

sub _die {
  require Carp::Clan;
  Carp::Clan->import("^$CLASS");
  Carp::Clan::croak(@_);
}

sub _catpath {
  my @path = grep { defined } @_;
  my $str = shift @path;
  while (@path) {
    my $next = shift @path;
    $str .= (substr($str, -1, 1) eq '/' ? '' : '/') . $next;
  }
  return $str;
}

sub _loaded {
  no strict 'refs';
#  use Data::Dumper;
  my $class = shift;
#  warn "$class :: " . Dumper \%{$class . '::'};
  return keys %{$class . '::'};
}


=head2 handler

=cut

sub handler ($) {
  my $class = _STRING(shift) || 
    _die "argument to handler() must be class name or stub";

  $class = caller() . "::$class" unless $class =~ s/^\+//;

  return sub {
    unless (_loaded($class)) {
      #warn "loading $class\n";
      eval "require $class";
      die $@ if $@;
      eval { $class->isa($CLASS) } or _die("$class must be isa $CLASS");
      die $@ if $@;
    }
    
#    use Data::Dumper;
#    warn "about to call $class->new with " . Dumper(\@_);
    return $class->new({
      (map {; "__$_" => $class->_site->{$_} } qw(scheme host port)),
      %{+shift},
    });
  };
}

=head2 class

=cut

sub class ($) {
  my $site = _HASH(shift) || _die "argument to class() must be hashref";
  my $caller = _STRING(shift) || caller;

  my $class = Package::Generator->new_package({
    base => $caller,
    isa  => $CLASS,
  });

  $class->setup_site($site);
  return "+$class";
}

=head2 permissive

=cut

sub permissive () {
  # deliberately avoid prototype
  return handler &class({ permissive => 1 }, scalar caller);
}

1;
