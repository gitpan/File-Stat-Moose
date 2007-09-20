#!/usr/bin/perl -d:DProf

use lib 'lib', '../lib';
use File::Stat::Moose;


foreach (1..10000) {
    my $size = (new File::Stat::Moose file=>'/etc/passwd')->size;
}

print "tmon.out data collected. Call dprofpp\n";
