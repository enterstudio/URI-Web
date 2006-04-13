package URI::Site::Node;

use strict;
use warnings;

use base qw(Class::Accessor::Fast
            Class::Data::Inheritable
          );

use Socket;
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
  for my $meth (qw(scheme host)) {
    Sub::Install::install_sub({
      as   => uc($meth),
      code => sub {
        my ($self, $opt) = @_;
        return $self->_lookup($meth, $opt);
      },
    });
  }
}

sub PORT {
  my ($self, $opt) = @_;
  my $str = $self->PATH;
  $opt ||= {};
  if ($self->__scheme and not $opt->{no_default_port}) {
    #warn "$str: (possibly) looking up parental port, no default\n";
    return $self->_lookup('port', { %$opt, no_default_port => 1 })
      || scalar getservbyname($self->SCHEME, 'tcp');
  }
  #warn "$str: looking up parental port, possibly with default allowed\n";
  return $self->_lookup('port', $opt);
}

sub _lookup {
  my ($self, $name, $opt) = @_;
  my $public  = uc($name);
  my $private = "__$name";

  $opt ||= {};
  return $self->_env($public) if !$opt->{clean} && $self->_env($public);
  my $val = $self->$private;
  return $val if defined $val;
  return unless $self->__parent;
  return $self->__parent->$public($opt);
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

sub _env {
  my ($self, $name) = @_;
  my $var = sprintf(
    "SITE_%s_%s_%s",
    $self->_clean_host, $self->_clean_path, $name,
  );
  $var =~ tr{./}{__};
  $var =~ s/_+/_/g;
  
  #warn "looking for \$ENV{$var}\n";
  return $ENV{$var};
}

sub _clean_path {
  my $self = shift;
  $self->{_clean_path} ||= $self->PATH({ clean => 1 });
}

sub _clean_host {
  my $self = shift;
  $self->{_clean_host} ||= $self->HOST({ clean => 1 });
}

sub PATH {
  my ($self, $opt) = @_;
  $opt ||= {};
  
  my $path = $self->__path;
  my $ppath;

  # XXX this is all pretty ugly  
  if ($path && $path =~ m!^/! or !$self->__parent) {
    $ppath = {
      clean => "",
      env   => "",
    };
  } else {
    $ppath = {
      clean => $self->__parent->PATH({ %$opt, clean => 1 }),
      env   => $self->__parent->PATH($opt),
    };
  }

  $path = $opt->{clean} ? $path : $self->_env('PATH') || $path;
  $path = _catpath($ppath->{$opt->{clean} ? 'clean' : 'env'}, $path);

  my $args = $self->__args;
  if (!$opt->{clean} && %$args) {
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

  for my $key (qw(SCHEME HOST PORT)) {
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

URI::Site::Node

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

Return a URI object.  Since URI::Site::Nodes stringify to
this method, you will only rarely need to call it.

=cut
