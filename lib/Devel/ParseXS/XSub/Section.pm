package Devel::ParseXS::XSub::Section;


use Class::Tiny qw[ lineno value ],
    {
     context => sub { [] },
    } ;

# use only as class method!
sub create {

    my ( $me, $class ) = (shift,shift);

    no strict 'refs';

    $class = join( '::', $me, $class );

    return $class->new( @_ );
}

package Devel::ParseXS::XSub::ALIAS;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::C_ARGS;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::CASE;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::CLEANUP;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::CODE;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::INIT;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::INPUT;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::INTERFACE;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::INTERFACE_MACRO;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::OUTPUT;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::OVERLOAD;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::PPCODE;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::POSTCALL;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::PREINIT;

use parent -norequire => 'Devel::ParseXS::XSub::Section';

package Devel::ParseXS::XSub::PROTOTYPE;

use parent -norequire => 'Devel::ParseXS::XSub::Section';


1;
