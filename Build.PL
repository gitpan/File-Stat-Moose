#!/usr/bin/perl

use Module::Build;

use strict;
use warnings;

my $build = Module::Build->new(
    module_name => 'File::Stat::Moose',
    dist_author => 'Piotr Roszatycki <dexter@debian.org>',
    license => 'perl',
    requires => {
        'perl'               => 5.006,
        'Moose'              => 0,
        'Exception::Base'    => 0,
        'Exception::System'  => 0,
    },
    optional => {
    },
    build_requires => {
        'Test::Unit::Lite'   => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL', 'Makefile', 'pm_to_blib',
        'README', 'cover_db',
        'File-Stat-Moose-*',
    ],
);

$build->create_build_script;
