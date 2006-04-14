package URI::Web;

use warnings;
use strict;

use base qw(URI::Web::Node
            Class::Data::Inheritable
          );

__PACKAGE__->mk_classdata('_site');

use Socket;
use URI;
use URI::Web::Leaf;
use URI::Web::Util qw(_die _load_class);
use Params::Util qw(_SCALAR _HASH _ARRAY _CALLABLE _STRING);
use Data::OptList;
use Sub::Install ();

use Sub::Exporter -setup => {
  collectors => { -base => \&_build_base },
};

sub _build_base {
  my ($value, $name, $cfg, $args, $class, $into) = @_;

  {
    no strict 'refs';
    push @{$into . "::ISA"}, $class;
  }

  $into->setup_site($value);

  return 1;
}

=head1 NAME

URI::Web - site map

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  package URI::Web::Mine;

  use URI::Web -base => \%arg;

  # or
  use base 'URI::Web';
  __PACKAGE__->setup_site(\%arg);

=head1 METHODS

=head2 setup_site

=cut

sub setup_site {
  my ($class, $arg) = @_;
  $arg = { map => $arg } if _ARRAY($arg);

  $arg->{branches} = {};

  $arg->{map} = Data::OptList::expand_opt_list(
    $arg->{map}, "$class site map",
  );

  $class->_site($arg);
  $class->_setup_site_map($arg->{map});

  if ($arg->{permissive}) {
    eval sprintf <<'', $class;
package %s;
use URI::Web::Permissive;
URI::Web::Permissive->import('-all');

    die $@ if $@;
  }
}

sub _setup_site_map {
  my ($class, $map) = @_;

  while (my ($key, $val) = each %$map) {
    if (_SCALAR($val)) {
      $val = URI::Web::Util::handler(
        URI::Web::Util::class({
          path       => $$val,
          permissive => 1,
        }),
      );
    } elsif (_ARRAY($val)) {
      $val = URI::Web::Util::handler(
        URI::Web::Util::class({ map => $val }),
      );
    } elsif (not defined $val) {
      $val = {
        class => 'URI::Web::Leaf',
      };
    }

    unless (_HASH($val)) {
      if (_CALLABLE($val)) {
        my $code = $val;
        $val = { handler => $code };
      } else {
        _die "unknown $class site map type: $val";
      }
    }

    $val->{class} || $val->{handler} ||
      _die("value '$key' requires one of 'class' or 'handler' is required");

    $val->{handler} ||= sub {
      _load_class($val->{class});
      shift->_child(
        $val->{class},
        __path => $val->{class}->_site->{path} || $key,
        __args => shift,
        map {; "__$_" => $val->{class}->_site->{$_} }
          qw(scheme host port),
      );
    };

    # allow leading / on paths
    my $meth = $key;
    $meth =~ s!^/+!!;
    Sub::Install::install_sub({
      into => $class,
      code => $val->{handler},
      as   => $meth,
    });

    $class->_site->{branches}->{$meth} = $val;
  }
}

=head2 ROOT

=cut

sub ROOT {
  my $class = shift;
  return $class->new({
    (map {; "__$_" => $class->_site->{$_} } qw(scheme host port path)),
    @_,
  });
}

sub _child {
  my $self = shift;
  my $kidclass = shift;
  #use Data::Dumper;
  #warn "creating new $kidclass with " . Dumper({ __parent => $self, @_ });
  return $kidclass->new({
    __parent => $self,
    @_,
  });
}

sub _canon_path {
  my $path = shift->SUPER::_canon_path(shift);
  $path = "$path/" if $path and substr($path, -1, 1) ne '/';
  return $path;
}

=head2 PARSE

=cut

sub PARSE {
  my ($class, $url) = @_;
  my $uri = URI->new($url)->canonical;

  my $self = ref($class) ? $class : $class->ROOT;

  my $name = ref($self);
  #warn "$name: parsing '$uri'";

  # choosing a branch: scheme/host/port can all be
  # overridden at the deepest level, so we don't want to
  # search based on those -- it has the potential to take
  # too long.
  #
  # instead, start looking at the path.  if one of the
  # branches matches, use it.  otherwise, start looking down
  # each branch for an absolutely stated path.
  # 
  # XXX how do we handle path_args?

  my @path = split m!/+!, $uri->path;
  shift @path until !@path or length $path[0];
  
  # XXX bogus, should check host/scheme/port
  return $self unless (@path);

  my $map = $class->_site->{map};
  die "XXX WTF" unless %$map;

  # 

  my $first = shift(@path);
  my $found;
  #warn "looking for '$first'\n";

  my $match = $self->can($first);
  if ($match) {
    $found = $self->$match;
  } else {
    my @q = map {
      [ $_ => $class->_site->{branches}->{$_} ]
    } keys %{ $class->_site->{branches} };
    while (@q and not $found) {
      my ($name, $mapent) = @{ shift @q };
      #use Data::Dumper;
      #warn Dumper({ $name => $mapent });
    }
  }

  # XXX TODO
  return unless $found;

  # XXX totally bogus
  if (@path and $path[0] =~ /^\d+$/) {
    $found->_args(shift @path);
  }
  
  # XXX not handling scheme/host/port
  return $found->PARSE(join "/", @path);
}

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-uri-web at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-Web>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::Web

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-Web>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-Web>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-Web>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-Web>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of URI::Web
