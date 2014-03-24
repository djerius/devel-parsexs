[
    all(
        isa( AST( 'Module' ) ),
        methods(
            module => 'module',
            attr   => superhashof( { lineno => 1 } ),
        ),
    ),
    all(
        isa( AST( 'CPP' ) ),
        methods(
            contents => ['#if 1'],
            attr     => superhashof( { lineno => 3 } ),
        ),
    ),
    all(
        isa( AST( 'XSub' ) ),
        methods(
            func_name   => 'gtk_window_get_accept_focus',
            return_type => 'gboolean',
            attr        => superhashof( { lineno => 5 } ),
            args        => methods(
                count => 1,
                [ element => 0 ] => methods(
                    name   => 'window',
                    c_type => 'GtkWindow *',
                    attr   => superhashof( { lineno => 5 } ),
                ),
            ),
        ),
    ),
    all(
        isa( AST( 'XSub' ) ),
        methods(
            func_name   => 'gtk_window_set_accept_focus',
            return_type => 'void',
            attr        => superhashof( { lineno => 7 } ),
            args        => methods(
                count => 2,
                [ element => 0 ] => methods(
                    name   => 'window',
                    c_type => 'GtkWindow *',
                    attr   => superhashof( { lineno => 7 } ),
                ),
                [ element => 1 ] => methods(
                    name   => 'setting',
                    c_type => 'gboolean',
                    attr   => superhashof( { lineno => 7 } ),
                ),
            ),
        ),
    ),
    all(
        isa( AST( 'CPP' ) ),
        methods(
            contents => ['#endif'],
            attr     => superhashof( { lineno => 9 } ),
        ),
    ),
    all(
        isa( AST( 'Comment' ) ),
        methods(
            contents => [
                '## void gtk_window_set_destroy_with_parent (GtkWindow *window, gboolean setting)'
            ],
            attr => superhashof( { lineno => 11 } ),

        ),
    ),
    all(
        isa( AST( 'XSub' ) ),
        methods(
            func_name   => 'gtk_window_set_destroy_with_parent',
            return_type => 'void',
            attr        => superhashof( { lineno => 12 } ),
            count       => 1,
            [ element => 0 ] => isa( AST( 'XSub::INPUT' ) ),
            args => methods(
                count => 2,
                [ element => 0 ] => methods(
                    name   => 'window',
                    c_type => 'GtkWindow *',
                    attr   => superhashof( {
                            lineno       => 13,
                            input_lineno => 14
                        }
                    ),
                ),
                [ element => 1 ] => methods(
                    name   => 'setting',
                    c_type => 'gboolean',
                    attr   => superhashof( {
                            lineno       => 13,
                            input_lineno => 15
                        }
                    ),
                ),
            ),
        ),
    ),
];

__DATA__
MODULE = module

#if 1

gboolean gtk_window_get_accept_focus (GtkWindow *window)

void gtk_window_set_accept_focus (GtkWindow *window, gboolean setting)

#endif

## void gtk_window_set_destroy_with_parent (GtkWindow *window, gboolean setting)
void
gtk_window_set_destroy_with_parent (window, setting)
	GtkWindow * window
	gboolean    setting
