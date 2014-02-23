use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Devel-ParseXS';
all_from 'lib/Devel/ParseXS.pm';
author   q{Diab Jerius <djerius@cpan.org>};
license  'perl';

perl_version 5.006;

tests_recursive('t');

resources (
   license    => 'http://www.gnu.org/licenses/gpl-3.0.html',
   repository => 'https://bitbucket.org/Diab Jerius/Devel-ParseXS',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-ParseXS',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
   'Test::Fatal' => 0,
);

requires (
    'Class::Tiny' => 0,
    'IO::Unread' => 0,
   #'ABC'              => 1.6,
   #'Foo::Bar::Module' => 5.0401,
);

install_as_cpan;
auto_install;
WriteAll;
