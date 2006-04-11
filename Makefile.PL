use strict;
use warnings;
use inc::Module::Install;

name 'URI-Site';
author 'Hans Dieter Pearcey <hdp@cpan.org>';
all_from;

build_requires 'Test::More' => 0;

requires 'URI'            => 0;
requires 'Sub::Exporter'  => 0;

auto_install;
WriteAll;
