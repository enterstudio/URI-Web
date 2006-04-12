package URI::Site::Object;

use strict;
use warnings;

use base qw(Class::Accessor::Fast
            Class::Data::Inheritable
          );

use URI::Site::Util qw(_die _catpath);
use Params::Util qw(_ARRAY);
use Sub::Install ();
use Storable ();

BEGIN {
  __PACKAGE__->mk_accessors(
    qw(__parent __query),
  );
  __PACKAGE__->mk_ro_accessors(
    qw(__scheme __host __port __path __args),
  );
  __PACKAGE__->mk_classdata(
    qw(__path_args_optlist),
  );
}

use URI;
use overload (
  q("")    => 'URI',
  q(&{})   => 'WITH',
  fallback => 1,
);

BEGIN {
  for my $meth (qw(scheme host port)) {
    my $private = "__$meth";
    my $public  = uc($meth);
    Sub::Install::install_sub({
      code => sub {
        my $self = shift;
        my $val = $self->$private(@_);
        return $val if defined $val;
        return unless $self->__parent;
        return $self->__parent->$public(@_);
      },
      as   => $public,
    });
  }
}

# backwards compat
sub _but_with  { shift->WITH(@_) }

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  $self->{__args}  ||= {};
  $self->{__query} ||= {};

  return $self;
}

sub PATH {
  my ($self) = @_;
  my $path;

  if ($self->__path && $self->__path =~ m!^/! or !$self->__parent) {
    $path = $self->__path;
  } else {
    $path = _catpath($self->__parent->PATH, $self->__path);
  }

  my $args = $self->__args;
  if (%$args) {
    my $path_args = $self->__path_args;
    
    for my $name (keys %$path_args) {
      my $code = $path_args->{$name} || sub { shift };
      next unless defined $args->{$name};
      $path = _catpath($path, $code->($args->{$name}));
    }
  }

  return $path;
}

sub __path_args { 
  my $class = shift;
  return {} unless $class->_site->{path_args};
  $class->__path_args_optlist || $class->__path_args_optlist(
    Data::OptList::expand_opt_list(
      $class->_site->{path_args}, "site object path args",
    ),
  );
}

sub URI {
  my ($self) = @_;

  my $uri = URI->new(sprintf(
    "%s://%s:%s/%s",
    $self->SCHEME, $self->HOST, $self->PORT,
    $self->_canon_path($self->PATH),
  ));

  $uri->query_form($self->__query) if %{$self->__query};

  return $uri->canonical;
}

sub WITH {
  my ($self, $arg) = @_;
  my $pa = $self->__path_args;

  my $clone;

  if (my $query = delete $arg->{__query}) {
    $clone = Storable::dclone($self);
    $clone->__query($query);
  }

  for my $key (keys %$arg) {
    next unless exists $pa->{$key};
    my $val = delete $arg->{$key};
    $clone ||= Storable::dclone($self);
    $clone->__args->{$key} = $val;
  }

  if (%$arg) {
    unless ($self->__parent) {
      require Data::Dumper;
      _die "WITH: args remaining and no parent: " . Data::Dumper::Dumper($arg);
    }
    $clone ||= Storable::dclone($self);
    $clone->__parent($self->__parent->WITH($arg));
  }

  return $clone || $self;
}

sub QUERY {
  my ($self, $arg) = @_;
  return $self->WITH({ __query => $arg });
}

sub QUERY_PLUS {
  my ($self, $arg) = @_;
  return $self->WITH({ __query => {
    %{$self->__query}, %$arg
  }});
}

sub _canon_path {
  my $path = $_[1];
  $path =~ s!^/!!;
  $path =~ s!//+!/!g;
  return $path;
}

1;

__END__

=head1 NAME

URI::Site::Object

=head1 DESCRIPTION

base class for URI::Site branches and leaves

=head1 METHODS

=head2 new

=head2 SCHEME

Defaults to 'http'.

=head2 HOST

=head2 PORT

Defaults to the result of C<< getservbyname >> for the
scheme.

=head2 PATH

=head2 WITH

=head2 QUERY

=head2 QUERY_PLUS

=head2 URI

Return a URI object.  Since URI::Site::Objects stringify to
this method, you will only rarely need to call it.

=cut
