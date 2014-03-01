MODULE = Trial::Foo  PACKAGE = Foo::Bar PREFIX = Bar

char *
func( );

char *
func_ellipsis( ... )

char *
func_int_a( int a );

char *
func_int_a_ellipsis( int a, ... )

char *
func_int_a_int_b( int a, int b );

char *
func_int_a_int_b_ellipsis( int a, int b, ... )


char *
func_char_star_a( char * a );

char *
func_char_starstar_a( char ** a )


char *
func_char_star_a_a1( char * a = "a1" );

char *
func_char_star_a_a2_ellipsis( char * a = "a2", ... )

char *
func_char_star_a_a3_int_b_1( char * a = "a3", int b = 1 );

char *
func_char_star_a_a4_int_b_2_ellipsis( char * a = "a4", int b = 2, ... )

