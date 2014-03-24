#! perl

requires 'Class::Tiny',        '0.014';
requires 'Safe::Isa',          '1.000004';
requires 'perl',               '5.008';
requires 'ExtUtils::Typemaps', '3.22';


on test => sub {
    requires 'Data::Section', '0.200005';
    requires 'Test::Fatal',   '0.013';
    requires 'Test::More',    '1.001002';
    requires 'Test::Deep';
};

on develop => sub {

    requires 'Module::Install';
    requires 'Module::Install::CPANfile';

};
