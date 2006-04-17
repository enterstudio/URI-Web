package URI::Web::Node;

use strict;
use warnings;

use base qw(Class::Accessor::Fast
            Class::Data::Inheritable
          );

use Socket;
use URI::Web::Util qw(_die _catpath);
use Params::Util qw(_ARRAY);
use Sub::Install ();
use Storable ();
use Scalar::Util ();

BEGIN {
  __PACKAGE__->mk_accessors(
    qw(__parent __path __args __query),
  );
  __PACKAGE__->mk_ro_accessors(
    qw(__scheme __host __port),
  );
  __PACKAGE__->mk_classdata('_site');
  __PACKAGE__->mk_classdata('__path_args_optlist');
}

use URI;
use overload (
  q("")    => 'URI',
  q(&{})   => 'WITH',
  fallback => 1,
);

sub PARENT { shift->__parent }

sub SCHEME {
  my ($self, $opt) = @_;
  return $self->_lookup('scheme', $opt) || 'http';
}

sub HOST {
  my ($self, $opt) = @_;
  return $self->_lookup('host', $opt);
}

sub PORT {
  my ($self, $opt) = @_;
  #my $str = $self->PATH;
  $opt ||= {};
  if ($self->__scheme and not $opt->{no_default_port}) {
    #warn "$str: (possibly) looking up parental port, no default\n";
    return $self->_lookup('port', { %$opt, no_default_port => 1 })
      || scalar getservbyname($self->__scheme, 'tcp');
  }
  #warn "$str: looking up parental port, possibly with default allowed\n";
  return $self->_lookup('port', $opt) || scalar getservbyname($self->SCHEME, 'tcp'); 
}

sub _lookup {
  my ($self, $name, $opt) = @_;
  my $public  = uc($name);
  my $private = "__$name";

  $opt ||= {};
  
  my @q = $self;
  while (@q) { 
    my $obj = shift @q;
    #warn "checking $public on " . overload::StrVal($obj) . "\n";
    if (!$opt->{canonical}) {
      return $obj->_env($public) if defined $obj->_env($public);
    }

    my $val = $obj->$private;
    return $val if defined $val;
    
    push @q, grep { defined } $obj->__parent;
  }
}

sub _gather_path {
  my ($self, $opt) = @_;
  # 'stop' gets current path segment
  $opt->{stop}    ||= sub { substr(shift, 0, 1) eq '/' };
  # 'segment' gets object
  $opt->{segment} ||= sub { shift->__path };

  my $path = '';
  my @q = $self;

  while (@q) {
    my $obj = shift @q;
    my $segment = $opt->{segment}->($obj);
    $path = _catpath($segment, $path);
    return $path if !$obj->__parent || $opt->{stop}->($segment);
    push @q, $obj->__parent;
  }
  return '';
}
  
# backwards compat
sub _but_with  { shift->WITH(@_) }

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  $self->{__args}  ||= {};
  $self->{__query} ||= {};

  # canonicalize
  $self->_args($self->__args);

  return $self;
}

sub _env {
  my ($self, $name) = @_;
  my $var = sprintf(
    "SITE_%s_%s",
    ($self->_site->{env} ||
       join("_", $self->_canonical_host, $self->_canonical_path)
     ), $name,
  );
  $var =~ tr{./}{__};
  $var =~ s/_+/_/g;
  
  #warn "looking for \$ENV{$var}\n";
  return $ENV{$var};
}

sub _canonical_path {
  my $self = shift;
  $self->{_canonical_path} ||= $self->_gather_path;
}

sub _canonical_host {
  my $self = shift;
  $self->{_canonical_host} ||= $self->HOST({ canonical => 1 });
}

sub PATH {
  my ($self, $opt) = @_;
  $opt ||= {};

  return $self->_gather_path({
    segment => sub {
      my $obj = shift;
      my $pa   = $obj->__path_args;
      my $args = $obj->_args;
      # XXX check env here:
      my @path = $obj->_env('PATH') || $obj->__path;
      for my $argname (keys %$args) {
        next unless exists $pa->{$argname};
        my $code = $pa->{$argname} || sub { 
          defined($_[0]) ? $_[0] : ''
        };
        push @path, $code->($args->{$argname});
      }
      return @path ? _catpath(@path) : '';
    },
  });
}

sub _args {
  my $self = shift;
  if (@_) {
    my $args = shift;
    my $pa   = $self->__path_args;
    if (Scalar::Util::blessed($args) || !ref($args) and keys %$pa == 1) {
      $args = { keys %$pa => $args };
    }
    $self->__args($args);
  }
  return $self->__args;
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

sub _clone { Storable::dclone(shift) }

sub WITH {
  my ($self, $arg) = @_;
  #warn "getting path_args for " . overload::StrVal($self);
  my $pa = $self->__path_args;

  my $clone;

  if (my $query = delete $arg->{__query}) {
    $clone = $self->_clone;
    $clone->__query($query);
  }

  for my $key (keys %$arg) {
    next unless exists $pa->{$key};
    my $val = delete $arg->{$key};
    $clone ||= $self->_clone;
    $clone->__args->{$key} = $val;
  }

  for my $key (qw(SCHEME HOST PORT PATH PARENT)) {
    my $val = delete $arg->{$key};
    next unless defined $val;
    $clone ||= $self->_clone;
    my $private = '__' . lc($key);
    $clone->{$private} = $val;
  }

  if (%$arg) {
    unless ($self->__parent) {
      require Data::Dumper;
      _die "WITH: args remaining and no parent: " . Data::Dumper::Dumper($arg);
    }
    $clone ||= $self->_clone;
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

URI::Web::Node

=head1 DESCRIPTION

base class for URI::Web branches and leaves

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

Return a URI object.  Since URI::Web::Nodes stringify to
this method, you will only rarely need to call it.

=head2 PARENT

=cut
