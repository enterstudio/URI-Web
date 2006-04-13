package URI::Site;

use warnings;
use strict;

use base qw(URI::Site::Node
            Class::Data::Inheritable
          );

__PACKAGE__->mk_classdata('_site');

use lib '/home/hdp/svk/export/trunk/lib';

use Socket;
use URI::Site::Leaf;
use URI::Site::Util qw(_die);
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

URI::Site - site map

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  package URI::Site::Mine;

  use URI::Site -base => \%arg;

  # or
  use base 'URI::Site';
  __PACKAGE__->setup_site(\%arg);

=head1 METHODS

=head2 setup_site

=cut

my %DEFAULT = (
  scheme => 'http',
);

sub setup_site {
  my ($class, $arg) = @_;
  $arg = { map => $arg } if _ARRAY($arg);

  $arg->{map} = Data::OptList::expand_opt_list(
    $arg->{map}, "$class site map",
  );

  $arg->{scheme} ||= $DEFAULT{scheme};
  $arg->{port}   ||= getservbyname($arg->{scheme}, 'tcp');

  $class->_setup_site_map($arg->{map});

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
      $val = URI::Site::Util::handler(
        URI::Site::Util::class({ map => $val }),
      );
    }

    if (not defined $val) {
      $code = sub { shift->_child(
        'URI::Site::Leaf', 
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
      code => $code,
      as   => $key,
    });
  }
}

=head2 root

=cut

sub root {
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

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-uri-site at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-Site>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::Site

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-Site>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-Site>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-Site>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-Site>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of URI::Site
