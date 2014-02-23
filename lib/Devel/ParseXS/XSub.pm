package Devel::ParseXS::XSub;

use base 'Devel::ParseXS::Element';

use Class::Tiny qw[ decl return_type class func_name ],
    {
     context => sub { [] },
     args    => sub { [] },
    };

1;
