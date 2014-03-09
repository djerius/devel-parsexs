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
   repository => 'https://bitbucket.org/djerius/devel-parsexs',
#   repository => 'https://github.com/djerius/devel-parsexs.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-ParseXS',
);

install_as_cpan;

cpanfile;
auto_install;
WriteAll;
