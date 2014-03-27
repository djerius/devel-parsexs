[
    isa( AST( 'Module' ) ),
    all(
        isa( AST( 'XSub' ) ),
        methods(
            func_name   => 'mmap_write',
            return_type => 'void',
            [ element, 0 ] => isa( AST( 'XSub::INPUT' ) ),
            [ element, 1 ] => all(
                isa( AST( 'XSub::PPCODE' ) ),
                methods(
                    [ element, 0 ] => isa( AST( 'Data' ) ),
                    [ element, 1 ] => isa( AST( 'Comment' ) ),
                    [ element, 2 ] => isa( AST( 'Data' ) ),
                ),
            ),
        ),
    ),
];
__DATA__
MODULE = IPC::Mmap		PACKAGE = IPC::Mmap

void
mmap_write(addr, maxlen, off, var, len)
	SV *  addr
	int   maxlen
	int   off
	SV * var
	int   len
    PPCODE:
        UV tmp = SvUV(addr);
	    caddr_t lcladdr = INT2PTR(caddr_t, (tmp + off));
 		STRLEN varlen;
 		char * ptr;

#		printf("\nmmap_write: addr %p maxlen %i off %i len %i\n",
#			lcladdr, maxlen, off, len);

		ptr = SvPV(var, varlen);
		if (len > (int)varlen)
			len = varlen;
