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
    qw(__proto __host __port __path __args),
  );
  __PACKAGE__->mk_classdata(
    qw(__path_args_optlist),
  );
}

use URI;
use overload (
  q("")    => '_uri',
  q(&{})   => '_with',
  fallback => 1,
);

BEGIN {
  for my $meth (qw(proto host port)) {
    my $private = "__$meth";
    my $public  = "_$meth";
    Sub::Install::install_sub({
      code => sub {
        my $self = shift;
        my $str = overload::StrVal($self);
        my $val = $self->$private(@_);
        unless (defined $val) {
          #warn "$str: looking at parent for $meth\n";
          unless ($self->__parent) {
            #warn "$str: oops, no parent\n";
            return;
          }
          $val = $self->__parent && $self->__parent->$public(@_);
          #warn "$str: parent said: $val\n";
        }
        #warn "$str->$public: $val\n";
        return $val;
      },
      as   => $public,
    });
  }
}

# consistency
sub _parent    { shift->__parent(@_) }

# backwards compat
sub _but_with  { shift->_with (@_) }
# TT compat
sub WITH       { shift->_with (@_) }
sub QUERY      { shift->_query(@_) }
sub QUERY_PLUS { shift->_query_plus(@_) }

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new(@_);

  #use Data::Dumper;
  #warn Dumper($self);
  $self->{__args}  ||= {};
  $self->{__query} ||= {};

  return $self;
}

sub _path {
  my ($self) = @_;
  my $path;
  unless ($self->__path) {
    use Data::Dumper;
    #warn Dumper($self);
  }
  if ($self->__path && $self->__path =~ m!^/! or !$self->__parent) {
    $path = $self->__path;
  } else {
    $path = _catpath($self->__parent->_path, $self->__path);
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
  #warn overload::StrVal($self) . "->_path: $path\n";
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

sub _uri {
  my ($self) = @_;
  my $uri = URI->new(sprintf(
    "%s://%s:%s/%s",
    $self->_proto, $self->_host, $self->_port,
    $self->_canon_path($self->_path),
  ));
  $uri->query_form($self->__query) if %{$self->__query};
  return $uri->canonical;
}

sub _with {
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
      _die "_with args remaining and no parent: " . Data::Dumper::Dumper($arg);
    }
    $clone ||= Storable::dclone($self);
    $clone->__parent($self->__parent->_with($arg));
  }

  return $clone || $self;
}

sub _query {
  my ($self, $arg) = @_;
  return $self->_with({ __query => $arg });
}

sub _query_plus {
  my ($self, $arg) = @_;
  return $self->_with({ __query => {
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

=head2 WITH

=head2 QUERY

=head2 QUERY_PLUS

=head2 new

=cut
