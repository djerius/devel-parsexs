[
    isa( AST( 'Module' ) ),
    isa( AST( 'Boot' ) ),
    all(
        isa( AST( 'XSub' ) ),
        methods(
            func_name   => 'gtk_get_version_info',
            return_type => 'void',
        ),
    ),
];
__DATA__
MODULE = Gtk2		PACKAGE = Gtk2		PREFIX = gtk_

BOOT:
	{
	gperl_handle_logs_for ("Gtk");
	gperl_handle_logs_for ("Gdk");

	gperl_handle_logs_for ("GdkPixbuf");

#############################################################################
#############################################################################

void
gtk_get_version_info (class)
