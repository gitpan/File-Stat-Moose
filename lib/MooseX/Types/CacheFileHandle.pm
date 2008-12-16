#!/usr/bin/perl -c

package MooseX::Types::CacheFileHandle;

=head1 NAME

MooseX::Types::CacheFileHandle - Type for special cached file handle

=head1 SYNOPSIS

  package My::Class;
  use Moose;
  use MooseX::Types::CacheFileHandle;
  has fh => ( isa => 'CacheFileHandle' );

  package main;
  my $obj = My::Class->new( fh => \*_ );

=head1 DESCRIPTION

This module provides Moose type which represents opened file handle (glob
reference or object).

=cut


use strict;
use warnings;

our $VERSION = 0.03;

use Moose::Util::TypeConstraints;


subtype 'CacheFileHandle'
    => as 'GlobRef'
    => where { defined Scalar::Util::reftype($_)
               && Scalar::Util::reftype($_) eq 'GLOB'
               && $_ == \*_ }
    => optimize_as { defined $_[0]
                     && defined Scalar::Util::reftype($_[0])
                     && Scalar::Util::reftype($_[0]) eq 'GLOB'
                     && $_[0] == \*_ };


1;


__END__

=head1 SEE ALSO

L<Moose::Util::TypeConstraints>, L<File::Stat::Moose>.

=head1 AUTHOR

Piotr Roszatycki E<lt>dexter@debian.orgE<gt>

=head1 LICENSE

Copyright (C) 2007, 2008 by Piotr Roszatycki E<lt>dexter@debian.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
