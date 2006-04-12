package URI::Site;

use warnings;
use strict;

use lib '/home/hdp/svk/export/trunk/lib';

use base qw(
            Class::Data::Inheritable
            Class::Accessor::Class
          );

use URI;
use NEXT;
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

  if (ref $value eq 'ARRAY') {
    $value = { map => $value };
  }

  $into->setup_site($value);

  return 1;
}

__PACKAGE__->mk_classdata('_site_host');
__PACKAGE__->mk_classdata('_site_port');
__PACKAGE__->mk_class_accessors(
  '_site_path', '_site_map',
);

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

=head2 setup_site_host

=head2 setup_site_port

=head2 setup_site_path

=head2 setup_site_map

=cut

sub setup_site {
  my ($class, $arg) = @_;
  for my $key (keys %$arg) {
    my $meth = "setup_site_$key";
    $class->$meth($arg->{$key});
  }
}

sub setup_site_host { $_[0]->_site_host($_[1]) }
sub setup_site_port { $_[0]->_site_port($_[1]) }
sub setup_site_path { $_[0]->_site_path($_[1]) }

sub __obj {
  ref($_[0]) ? $_[0] : $_[0]->new
}

sub _host { shift->_site_host }
sub _port { shift->_site_port }

sub _gather_path {
  my ($class, $aref) = @_;
  push @$aref, $class->_site_path;
}

sub _slash {
  my ($self, $extra) = @_;
  return $self->_path . '/' . $extra;
}

sub _path { 
  my ($class) = @_;
  return $class->_site_path if $class->_site_path =~ m!^/!;
  my @path;
  $class->EVERY::_gather_path(\@path);
  return join "", @path;
}

sub setup_site_map  {
  my $class = shift;
  my $map = $class->_site_map($class->_canon_site_map(shift));
  for my $key (keys %$map) {
    $class->setup_site_map_entry($key => $map->{$key});
  }
}

sub setup_site_map_entry {
  my ($class, $key, $val) = @_;

  my $code;
  if (not defined $val) {
    warn "$class map entry: found $key: undef\n";
    $code = sub { URI->new(shift->__obj->_slash($key)) };
  } elsif (ref $val eq 'CODE') {
    warn "$class map entry: found $key: coderef\n";
    $code = sub { $val->(shift->__obj) };
  } else {
    die "unknown map entry: $key => $val";
  }

  Sub::Install::install_sub({
    into => $class,
    code => $code,
    as   => $key,
  });
}

sub _canon_site_map {
  my ($class, $map) = @_;
  $map = Data::OptList::expand_opt_list(
    $map, "$class site map",
  );
  
  use Data::Dumper;
  warn Dumper($map);

  return $map;
}

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-urix-site at rt.cpan.org>, or through the web interface at
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
