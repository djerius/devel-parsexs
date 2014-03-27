[
    isa( AST( 'Module' ) ),
    all(
        isa( AST( 'XSub' ) ),
        methods(
            func_name   => 'writeMessageEnd',
            return_type => 'int',
            args        => methods(
                [ element, 0 ] => methods(
                    c_type => 'SV *',
                    name   => undef,
                ),
            ),
            [ element, 0 ] => isa( AST( 'XSub::INPUT' ) ),
            [ element, 1 ] => isa( AST( 'XSub::CODE' ) ),
            [ element, 2 ] => isa( AST( 'XSub::OUTPUT' ) ),
        ),
    ),
];
__DATA__
MODULE = module

int
writeMessageEnd(SV *)
CODE:
{
  RETVAL = 0;
}
OUTPUT:
  RETVAL
