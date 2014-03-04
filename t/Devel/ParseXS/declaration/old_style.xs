MODULE = Trial::Foo  PACKAGE = Foo::Bar PREFIX = Bar

char *
func( )

char *
func_ellipsis( ... )

char *
func_int_a( a )
int a

char *
func_int_a_ellipsis( a, ... )
int a

char *
func_int_a_int_b( a, b )
int a
int b

char *
func_int_a_int_b_ellipsis( a, b, ... )
int a
int b

char *
func_char_star_a( a )
char * a

char *
func_char_starstar_a( a )
char ** a

char *
func_char_star_a_a1( a = "a1" )
char * a

char *
func_char_star_a_a2_ellipsis( a = "a2", ... )
char * a

char *
func_char_star_a_a3_int_b_1( a = "a3", b = 1 )
char * a
int b

char *
func_char_star_a_a4_int_b_2_ellipsis( a = "a4", b = 2, ... )
char * a
int b
