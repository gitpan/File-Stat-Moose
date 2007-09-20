#!/usr/bin/perl -I../lib

use IO::File;
use File::Stat::Moose;

$fh = new IO::File '/etc/passwd';
$st = new File::Stat::Moose file=>$fh;

print "Size: ", $st->size, "\n";    # named field
print "Blocks: ". $st->[12], "\n";  # numbered field

print $st->dump;
