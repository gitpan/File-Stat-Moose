#!/usr/bin/perl -c

package MooseX::Types::OpenHandle;

=head1 NAME

MooseX::Types::OpenHandle - Type for opened file handle

=head1 SYNOPSIS

  package My::Class;
  use Moose;
  use MooseX::Types::OpenHandle;
  has statfh => ( isa => 'OpenHandle' );

  package main;
  stat "/etc/passwd";
  my $obj = My::Class->new( statfh => \*_ );

=head1 DESCRIPTION

This module provides Moose type which represents special cached file handle -
underscore (C<_>) - which is used for C<stat> tests.

opened file handle (glob
reference or object).

=cut


use strict;
use warnings;

our $VERSION = 0.03;

use Moose::Util::TypeConstraints;


subtype 'OpenHandle'
    => as 'Ref'
    => where { defined Scalar::Util::reftype($_)
              && Scalar::Util::reftype($_) eq 'GLOB'
              && Scalar::Util::openhandle($_) }
    => optimize_as { defined $_[0]
                    && defined Scalar::Util::reftype($_[0])
                    && Scalar::Util::reftype($_[0]) eq 'GLOB'
                    && Scalar::Util::openhandle($_[0]) };


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
