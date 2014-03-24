[
    isa( AST( 'Module' ) ),
    isa( AST( 'Boot' ) ),
    all(
        isa( AST( 'XSub' ) ),
        methods(
            func_name   => 'gdk_gc_new',
            return_type => 'GdkGC_noinc *',
        ),
    ),
];
__DATA__
MODULE = Gtk2::Gdk::GC	PACKAGE = Gtk2::Gdk::GC	PREFIX = gdk_gc_

BOOT:
	/* the gdk backends override the public GdkGC with private,
	 * back-end-specific types.  tell gperl_get_object not to
	 * complain about them.  */
	gperl_object_set_no_warn_unreg_subclass (GDK_TYPE_GC, TRUE);



 ## taken care of by typemaps
 ## void gdk_gc_unref (GdkGC *gc)

 ##GdkGC * gdk_gc_new (GdkDrawable * drawable);
 ##GdkGC * gdk_gc_new_with_values (GdkDrawable * drawable, GdkGCValues * values);
=for apidoc
Create and return a new GC.

C<$drawable> is used for the depth and the display
(C<Gtk2::Gdk::Display>) for the GC.  The GC can then be used with any
drawable of the same depth on that display.

C<$values> is a hashref containing some of the following keys,

=cut
GdkGC_noinc*
gdk_gc_new (class, GdkDrawable * drawable, SV * values=NULL)
