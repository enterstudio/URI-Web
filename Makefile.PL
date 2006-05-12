use strict;
use warnings;
use inc::Module::Install;

name 'URI-Web';
author 'Hans Dieter Pearcey <hdp@cpan.org>';
all_from;

build_requires 'Test::More'    => 0;
build_requires 'Test::use::ok' => 0;

requires 'Class::Data::Inheritable' => 0;
requires 'Class::Accessor::Class'   => 0;
requires 'Params::Util'             => 0;
requires 'Package::Generator'       => 0;
requires 'Sub::Exporter'            => 0;
requires 'URI'                      => 0;
requires 'CGI::Expand'              => 0;

auto_install;
WriteAll;
