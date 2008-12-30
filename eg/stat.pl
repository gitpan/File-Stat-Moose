#!/usr/bin/perl -I../lib

use strict;

use File::Stat::Moose;

-f $ARGV[0] or die "Usage: $0 filename\n";
my $st = File::Stat::Moose->new( file => \*_ );

print "Size: ", $st->size, "\n";    # named field
print "Blocks: ". $st->[12], "\n";  # numbered field

print $st->dump;
