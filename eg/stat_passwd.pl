#!/usr/bin/perl -I../lib

use IO::File;
use File::Stat::Moose;

$fh = IO::File->new( $ARGV[0] || die "Usage: $0 filename\n" );
$st = File::Stat::Moose->new( file=>$fh );

print "Size: ", $st->size, "\n";    # named field
print "Blocks: ". $st->[12], "\n";  # numbered field

print $st->dump;
