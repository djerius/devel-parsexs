
[
    all(
        isa( AST( 'Module' ) ),
        methods(
            module  => 'Gtk2::Window',
            package => 'Gtk2::Window',
            prefix  => 'gtk_window_',
            attr    => superhashof( { lineno => 1 } ),
        ),
    ),

    all(
        isa( AST( 'Module' ) ),
        methods(
            module  => 'Gtk2::Window',
            package => 'Gtk2::WindowGroup',
            prefix  => 'gtk_window_group_',
            attr    => superhashof( { lineno => 3 } ),
        ),
    ),

    all(
        isa( AST( 'Comment' ) ),
        methods(
            contents => [ '## GtkWindowGroup * gtk_window_group_new (void)', ],
            attr     => superhashof( { lineno => 5 } ),

        ),
    ),

    all(
        isa( AST( 'XSub' ) ),
        methods(
            count       => 2,
            [ element => 0 ] => isa( AST( 'XSub::INPUT' ) ),
            [ element => 1 ] => isa( AST( 'XSub::C_ARGS' ) ),
            attr => superhashof( { lineno => 6 } ),
            args => methods(
                count => 1,
                [ element => 0 ] => methods(
                    name   => 'class',
                    attr   => superhashof( {
                            lineno       => 7,
                        }
                    ),
                ),
            ),
        ),
    ),
];

__DATA__
MODULE = Gtk2::Window	PACKAGE = Gtk2::Window	PREFIX = gtk_window_

MODULE = Gtk2::Window	PACKAGE = Gtk2::WindowGroup	PREFIX = gtk_window_group_

## GtkWindowGroup * gtk_window_group_new (void)
GtkWindowGroup *
gtk_window_group_new (class)
    C_ARGS:
	/*void*/
