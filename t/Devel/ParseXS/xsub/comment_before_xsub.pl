[
    isa( AST( 'Module' ) ),
    isa( AST( 'Comment' ) ),
    all(
        isa( AST( 'XSub' ) ),
        methods(
            func_name   => 'gdk_drawable_get_size',
            return_type => 'void',
        ),
    ),
    all(
        isa( AST( 'XSub' ) ),
        methods(
            func_name   => 'gdk_drawable_set_colormap',
            return_type => 'void',
        ),
    ),
];

__DATA__
MODULE = Gtk2::Gdk::Drawable	PACKAGE = Gtk2::Gdk::Drawable	PREFIX = gdk_drawable_

 ## void gdk_drawable_get_size (GdkDrawable *drawable, gint *width, gint *height)
void gdk_drawable_get_size (GdkDrawable *drawable, OUTLIST gint width, OUTLIST gint height)

 ## void gdk_drawable_set_colormap (GdkDrawable *drawable, GdkColormap *colormap)
void
gdk_drawable_set_colormap (drawable, colormap)
	GdkDrawable *drawable
	GdkColormap *colormap

