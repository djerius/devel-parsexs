package Devel::XS::AST::XSub::Section;

use Carp;

use strict;
use warnings;


use Class::Tiny qw[ value ],
    {
     # additional attributes not managed by class
     attr => sub { {} },
     context => sub { [] },
    } ;


package Devel::XS::AST::XSub::ALIAS;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::C_ARGS;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::CASE;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::CLEANUP;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::CODE;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::INIT;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::INPUT;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::INTERFACE;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::INTERFACE_MACRO;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::OUTPUT;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::OVERLOAD;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::PPCODE;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::POSTCALL;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::PREINIT;

use parent -norequire => 'Devel::XS::AST::XSub::Section';

package Devel::XS::AST::XSub::PROTOTYPE;

use parent -norequire => 'Devel::XS::AST::XSub::Section';


1;
