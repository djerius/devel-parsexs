package Devel::ParseXS::XSub;

use base 'Devel::ParseXS::Element';

use Class::Tiny {

  line_no => 1,
  sections => sub { [] },
  return_type => undef,
  class => undef,
  func_name => undef,
  args => sub { [] },
};

1;
