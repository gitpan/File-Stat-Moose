#!/usr/bin/perl

use Module::Build;

use strict;
use warnings;

my $build = Module::Build->new(
    module_name => 'File::Stat::Moose',
    dist_author => 'Piotr Roszatycki <dexter@debian.org>',
    license => 'perl',
    requires => {
        'perl'                => 5.008,
        'constant::boolean'   => 0,
        'DateTime'            => 0,
        'Exception::Argument' => 0.05,
        'Exception::Base'     => 0.21,
        'Exception::System'   => 0.11,
        'Moose'               => 0,
        'Sub::Exporter'       => 0,
    },
    optional => {
    },
    build_requires => {
        'parent'              => 0,
        'Exception::Died'     => 0.04,
        'Exception::Warning'  => 0.03,
        'Test::Assert'        => 0.04,
        'Test::Unit::Lite'    => 0.11,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    recursive_test_files => 1,
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', '*.tgz', '*.ppd', '*.deb', '*.bat',
        'Makefile.PL', 'Makefile', 'pm_to_blib', 'README', 'cover_db',
        'Debian_CPANTS.txt',
        'File-Stat-Moose-*',
    ],
);

$build->create_build_script;
