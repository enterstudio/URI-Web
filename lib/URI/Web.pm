package URI::Web;

use warnings;
use strict;

use base qw(URI::Web::Node
            Class::Data::Inheritable
          );

__PACKAGE__->mk_classdata('_site');

use lib '/home/hdp/svk/export/trunk/lib';

use Socket;
use URI;
use URI::Web::Leaf;
use URI::Web::Util qw(_die);
use Params::Util qw(_ARRAY _CALLABLE _STRING);
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

  $arg->{map} = Data::OptList::expand_opt_list(
    $arg->{map}, "$class site map",
  );

  $class->_setup_site_map($arg->{map});

  if ($arg->{permissive}) {
    eval sprintf <<'', $class;
package %s;
use URI::Web::Permissive;
URI::Web::Permissive->import('-all');

    die $@ if $@;
  }

  $class->_site($arg);
}

sub _setup_site_map {
  my ($class, $map) = @_;
  my $code;
  while (my ($key, $val) = each %$map) {
    # this is ahead of the main switch because we want
    # handlers generated here to be treated the same as
    # handlers that were originally passed in
    if (_ARRAY($val)) {
      $val = URI::Web::Util::handler(
        URI::Web::Util::class({ map => $val }),
      );
    }

    if (not defined $val) {
      $code = sub { shift->_child(
        'URI::Web::Leaf', 
        __path => $key,
        @_
      ) };
    } elsif (_CALLABLE($val)) {
      $code = sub { $val->({
        __parent => shift,
        __path   => $key,
        __args   => shift,
      }) };
    } else {
      _die "unknown $class site map type: $val";
    }

    Sub::Install::install_sub({
      into => $class,
      code => $code,
      as   => $key,
    });
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
  my $uri = URI->new($url);

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
  # XXX right now there is no way to give an absolutely
  # stated path.
  #
  # XXX how do we handle path_args?

  my @path = grep { length } split m!/+!, $uri->path;
  
  # XXX bogus
  return $self unless (@path);

  my $map = $class->_site->{map};
  die "XXX WTF" unless %$map;

  my $first = shift(@path);
  #warn "looking for '$first'\n";
  my $branch = $self->$first || die "XXX WTF 2";

  if (@path and $path[0] =~ /^\d+$/) {
    $branch->_args(shift @path);
  }
  
  # XXX not handling scheme/host/port
  return $branch->PARSE(join "/", @path);
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
