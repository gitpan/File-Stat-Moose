#!/usr/bin/perl -al

use lib 'lib', '../lib';

package My::CoreStat;
our $n = 0;
sub test {
    my $size = (stat '/etc/passwd')[7];
    $n++;
}


package My::FileStat;
use File::stat;
our $n = 0;
sub test {
    my $st = stat '/etc/passwd';
    my $size = $st->size;
    $n++;
}


package My::FileStatMoose;
use File::Stat::Moose;
our $n = 0;
sub test {
    my $size = File::Stat::Moose->new(file=>'/etc/passwd')->size;
    $n++;
}


package My::FileStatMooseFunc;
use File::Stat::Moose 'stat';
our $n = 0;
sub test {
    my $size = (stat '/etc/passwd')[7];
    $n++;
}

package main;

use Benchmark ':all';

my $result = timethese($ARGV[0] || -1, {
    '1_CoreStat'               => sub { My::CoreStat::test; },
    '2_FileStat'               => sub { My::FileStat::test; },
    '3_FileStatMoose'          => sub { My::FileStatMoose::test; },
    '4_FileStatMooseFunc'      => sub { My::FileStatMooseFunc::test; },
});

cmpthese($result);
