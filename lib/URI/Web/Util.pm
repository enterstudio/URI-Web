package URI::Web::Util;

use strict;
use warnings;

use Package::Generator;
use Params::Util qw(_STRING _HASH);
use Sub::Exporter -setup => {
  exports => [qw(_die _load_class _catpath handler class permissive
                 file_handler
               )],
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

sub _load_class {
  no strict 'refs';
#  use Data::Dumper;
  my $class = shift;
#  warn "$class :: " . Dumper \%{$class . '::'};
  unless (keys %{$class . '::'}) {
    eval "require $class";
    die $@ if $@;
    eval { $class->isa($CLASS) } or _die("$class must be isa $CLASS");
    die $@ if $@;
  }
}


=head2 handler

=cut

sub handler ($) {
  my $class = _STRING(shift) || 
    _die "argument to handler() must be class name or stub";

  $class = caller() . "::$class" unless $class =~ s/^\+//;

  return {
    class => $class,
  };
}

=head2 class

=cut

sub class ($) {
  my $site = _HASH(shift) || _die "argument to class() must be hashref";
  my $caller = _STRING(shift) || caller;

  my $class = Package::Generator->new_package({
    base => delete $site->{_base} || $caller,
    isa  => delete $site->{_isa}  || $CLASS,
  });

  $class->setup_site($site) if $class->can("setup_site");
  return "+$class";
}

=head2 file_handler

Return a handler which accepts filenames and returns leaves.

For example, to make a simple static html path handler, you
might use:

  # in map
  file_handler('html'),

  # in code, later
  $class->ROOT->html("foo.html")
  # http://somehost/html/foo.html

=cut

sub file_handler {
  my ($path) = @_;
  return $path => sub {
    my $self = shift;
    if (@_) {
      return $self->_child(
        'URI::Web::Leaf',
        __path => _catpath($path, shift),
      );
    } else {
      return $self->WITH({
        PARENT => $self,
        PATH   => $path,
      });
    } 
  };
}

=head2 permissive

=cut

sub permissive () {
  # deliberately avoid prototype
  return handler &class({ permissive => 1 }, scalar caller);
}

1;
