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
use CGI::Expand ();
use Data::OptList ();

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

# cache the results of getservbyname for speed -- hdp, 2007-01-23
my %_servbyname;
sub PORT {
  my ($self, $opt) = @_;
  #my $str = $self->PATH;
  $opt ||= {};
  if ($self->__scheme and not $opt->{no_default_port}) {
    #warn "$str: (possibly) looking up parental port, no default\n";
    return $self->_lookup('port', { %$opt, no_default_port => 1 })
      || ($_servbyname{$self->__scheme} ||=
        getservbyname($self->__scheme, 'tcp'));
  }
  #warn "$str: looking up parental port, possibly with default allowed\n";
  return $self->_lookup('port', $opt) || (
    $_servbyname{$self->SCHEME} ||= getservbyname($self->SCHEME, 'tcp')
  ); 
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

sub __path_arg_default { defined($_[0]) ? $_[0] : '' }

sub PATH {
  my ($self, $opt) = @_;
  $opt ||= {};

  return $self->_gather_path({
    segment => sub {
      my $obj = shift;
      my $pa   = $obj->__path_args;
      my $args = $obj->_args;
      my @path = $obj->_env('PATH') || $obj->__path;
      for my $path_arg (@$pa) {
        my ($name, $code) = @$path_arg;
        next unless exists $args->{$name};
        $code ||= \&__path_arg_default;
        push @path, $code->($args->{$name});
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
    if (Scalar::Util::blessed($args) || !ref($args) and @$pa == 1) {
      $args = { $pa->[0][0] => $args };
    }
    $self->__args($args);
  }
  return $self->__args;
}    

sub __path_args {
  my $class = shift;
  return [] unless $class->_site->{path_args};
  $class->__path_args_optlist || $class->__path_args_optlist(
    Data::OptList::mkopt(
      $class->_site->{path_args}, "site object path args",
    ),
  );
}

sub URI {
  my ($self) = @_;

  # the object may not have one or more of these. shut up warnings about it
  # which URI.pm will handle anyway. -- cmn, 2009-06-09
  my $uri;
  {
    no warnings 'uninitialized';
    $uri = URI->new(sprintf(
      "%s://%s:%s/%s",
      $self->SCHEME, $self->HOST, $self->PORT,
      $self->_canon_path($self->PATH),
    ));
  }

  $uri->query_form($self->__query) if %{$self->__query};

  return $uri->canonical;
}

# _clone does a shallow copy followed by a second-level shallow copy of certain
# attributes; we do this instead of dclone because it is faster and simpler to
# only copy the things we are actually going to change
sub _clone {
  my $self = shift;
  my $clone = bless {%$self} => ref($self);
  # XXX there's no test that points out why this is necessary -- hdp,
  # 2007-01-23
  delete $clone->{$_} for grep /^_canonical/, keys %$clone;
  for my $hkey (qw(__args __query)) {
    next unless $clone->{$hkey};
    $clone->{$hkey} = { %{ $clone->{$hkey} } };
  }
  return $clone;
}

sub WITH {
  my ($self, $arg) = @_;

  my $clone;

  if (my $query = delete $arg->{__query}) {
    $clone = $self->_clone;
    my $literal = delete $query->{_LITERAL};
    $query = CGI::Expand->collapse_hash($query);
    if ($literal) {
      # this only works because $query has already been
      # flattened by collapse_hash
      $query->{$_} = $literal->{$_} for keys %$literal;
    }
    $clone->__query($query);
  }

  for my $path_arg (@{$self->__path_args}) {
    my ($name) = @$path_arg;
    next unless exists $arg->{$name};
    my $val = delete $arg->{$name};
    $clone ||= $self->_clone;
    $clone->__args->{$name} = $val;
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
    %{CGI::Expand->expand_hash($self->__query)}, %$arg,
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
