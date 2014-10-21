#!/usr/bin/perl -c

package File::Stat::Moose;

=head1 NAME

File::Stat::Moose - Status info for a file - Moose-based

=head1 SYNOPSIS

  use File::Stat::Moose;
  open my $fh, '/etc/passwd';
  $st = File::Stat::Moose->new( file => $fh );
  print "Size: ", $st->size, "\n";    # named attribute
  print "Blocks: ". $st->[12], "\n";  # numbered attribute

=head1 DESCRIPTION

This class provides methods that returns status info for a file.  It is the
OO-style version of stat/lstat functions.  It also throws an exception
immediately after error is occurred.

=for readme stop

=cut


use 5.008;
use strict;
use warnings FATAL => 'all';

our $VERSION = 0.05;

use Moose;

# Additional types
use MooseX::Types::OpenHandle;
use MooseX::Types::CacheFileHandle;

# Run-time Assertions
use Test::Assert ':assert';

# TRUE/FALSE
use constant::boolean;

# atime, ctime, mtime attributes
use DateTime;


use Exception::Base (
    '+ignore_package' => [ __PACKAGE__, qr/^File::Spec(::|$)/, 'Sub::Exporter', qr/^Moose::/, qr/^Class::MOP::/ ],
);
use Exception::Argument;
use Exception::IO;


use overload (
    '@{}' => '_deref_array',
    fallback => TRUE,
);


use Sub::Exporter -setup => {
    exports => [

        # Get file status
        stat => sub {
            sub (;*) {
                my $st = __PACKAGE__->new(
                    file   => (defined $_[0] ? $_[0] : $_),
                    follow => TRUE,
                );
                return wantarray ? @{ $st } : $st;
            };
        },

        # Get link status
        lstat => sub {
            sub (;*) {
                my $st = __PACKAGE__->new(
                    file   => (defined $_[0] ? $_[0] : $_),
                    follow => FALSE,
                );
                return wantarray ? @{ $st } : $st;
            };
        },

    ],
    groups => { all => [ qw{ stat lstat } ] },
};


# File which is checked with stat
has file => (
    is        => 'ro',
    isa       => 'Str | FileHandle | CacheFileHandle | OpenHandle',
    required  => TRUE,
    predicate => 'has_file',
);

# Follow symlink or read symlink itself
has follow => (
    is       => 'ro',
    isa      => 'Bool',
    default  => FALSE,
);

# Speeds up stat on Win32
has sloppy => (
    is       => 'ro',
    isa      => 'Bool',
    default  => FALSE,
);

# Numeric informations about a file
has [ qw{ dev ino mode nlink uid gid rdev size blksize blocks } ] => (
    is       => 'ro',
    isa      => 'Maybe[Int]',
);

{
    foreach my $attr ( qw{ atime mtime ctime } ) {

        # Numeric informations about a file (time as unix timestamp)
        has "_${attr}_epoch" => (
            isa      => 'Maybe[Int]',
        );

        # Time as DateTime object (lazy evaluationed)
        has $attr => (
            is       => 'ro',
            isa      => 'Maybe[DateTime]',
            lazy     => TRUE,
            default  => sub {
                defined $_[0]->{"_${attr}_epoch"}
                ? DateTime->from_epoch( epoch => $_[0]->{"_${attr}_epoch"} )
                : undef
            },
            reader   => $attr,
            clearer  => "_clear_$attr",
        );

    };
};


## no critic (ProhibitBuiltinHomonyms)
## no critic (RequireArgUnpacking)

# Constructor calls stat method if necessary
sub BUILD {
    my ($self, $params) = @_;

    assert_not_null($self->{file}) if ASSERT;

    # Update stat info
    $self->stat;

    return TRUE;
};


# Call stat or lstat method
sub stat {
    my $self = shift;
    Exception::Argument->throw( message => 'Usage: $st->stat()' ) if @_ > 0 or not blessed $self;

    assert_not_null($self->{file}) if ASSERT;

    # Clear lazy attributes
    delete @{$self}{ qw{ atime mtime ctime } };

    local ${^WIN32_SLOPPY_STAT} = $self->{sloppy};

    if ($self->{follow}) {
        @{$self}{ qw{ dev ino mode nlink uid gid rdev size _atime_epoch _mtime_epoch _ctime_epoch blksize blocks } }
        = map { defined $_ && $_ eq '' ? undef : $_ }
          CORE::stat $self->{file} or Exception::IO->throw( message => 'Cannot stat' );
    }
    else {
        no warnings 'io';  # lstat() on filehandle
        @{$self}{ qw{ dev ino mode nlink uid gid rdev size _atime_epoch _mtime_epoch _ctime_epoch blksize blocks } }
        = map { defined $_ && $_ eq '' ? undef : $_ }
          CORE::lstat $self->{file} or Exception::IO->throw( message => 'Cannot lstat' );
    };

    return $self;
};


# Deprecated
sub lstat {
    my ($self) = @_;

    ## no critic (RequireCarping)
    warn "Method (File::Stat::Moose->lstat) is deprecated. Use method (stat).";

    confess "Cannot call method (File::Stat::Moose->lstat) with attribute (follow) set to false value" if not $self->follow;

    return $self->stat;
};


# Array dereference
sub _deref_array {
    my ($self) = @_;
    return [ @{$self}{ qw{ dev ino mode nlink uid gid rdev size _atime_epoch _mtime_epoch _ctime_epoch blksize blocks } } ];
};


# Module initialization
__PACKAGE__->meta->make_immutable();


1;


__END__

=begin umlwiki

= Component Diagram =

[            <<library>>       {=}
          File::Stat::Moose
 ---------------------------------
 File::Stat::Moose
 MooseX::Types::OpenHandle
 MooseX::Types::CacheFileHandle
 <<exception>> Exception::IO
 <<type>> OpenHandle
 <<type>> CacheFileHandle         ]

= Class Diagram =

[                                File::Stat::Moose
 ----------------------------------------------------------------------------------------
 +file : Str|FileHandle|CacheFileHandle|OpenHandle {ro, required}
 +follow : Bool {ro}
 +sloppy : Bool {ro}
 +dev : Maybe[Int] {ro}
 +ino : Maybe[Int] {ro}
 +mode : Maybe[Int] {ro}
 +nlink : Maybe[Int] {ro}
 +uid : Maybe[Int] {ro}
 +gid : Maybe[Int] {ro}
 +rdev : Maybe[Int] {ro}
 +size : Maybe[Int] {ro}
 +atime : Maybe[DateTime] {ro, lazy}
 +mtime : Maybe[DateTime] {ro, lazy}
 +ctime : Maybe[DateTime] {ro, lazy}
 +blksize : Maybe[Int] {ro}
 +blocks : Maybe[Int] {ro}
 #_atime_epoch : Maybe[Int] {ro}
 #_mtime_epoch : Maybe[Int] {ro}
 #_ctime_epoch : Maybe[Int] {ro}
 ----------------------------------------------------------------------------------------
 +update() : Self
 +stat() : Self
 <<deprecated>> +lstat() : Self
 <<utility>> +stat( file : Str|FileHandle|CacheFileHandle|OpenHandle = $_ ) : Self|Array
 <<utility>> +lstat( file : Str|FileHandle|CacheFileHandle|OpenHandle = $_ ) : Self|Array
 -_deref_array() : ArrayRef {overload="@{}"}
                                                                                         ]

[File::Stat::Moose] ---> <<exception>> [Exception::Argument] [Exception::IO]

=end umlwiki

=head1 IMPORTS

By default, the class does not export its symbols.

=over

=item stat

=item lstat

Imports C<stat> and/or C<lstat> functions.

  use File::Stat::Moose 'stat', 'lstat';

=item :all

Imports all available symbols.

  use File::Stat::Moose ':all';

=back

=head1 EXCEPTIONS

=over

=item Exception::Argument

Thrown whether a methods is called with wrong arguments.

=item Exception::IO

Thrown whether an IO error is occurred.

=back

=head1 ATTRIBUTES

=over

=item file : Str|FileHandle|CacheFileHandle|OpenHandle {ro, required}

Contains the file for check.  The attribute can hold file name or file
handler or IO object.

=item follow : Bool {ro}

If the value is true and the I<file> for check is symlink, then follows it
than checking the symlink itself.

=item sloppy : Bool {ro}

On Win32 L<perlfunc/stat> needs to open the file to determine the link count
and update attributes that may have been changed through hard links.  If the
I<sloppy> is set to true value, L<perlfunc/stat> speeds up by not performing
this operation.

=item dev : Maybe[Int] {ro}

ID of device containing file.  If this value and following has no meaning on
the platform, it will contain undefined value.

=item ino : Maybe[Int] {ro}

inode number.

=item mode : Maybe[Int] {ro}

Unix mode for file.

=item nlink : Maybe[Int] {ro}

Number of hard links.

=item uid : Maybe[Int] {ro}

User ID of owner.

=item gid : Maybe[Int] {ro}

Group ID of owner.

=item rdev : Maybe[Int] {ro}

Device ID (if special file).

=item size : Maybe[Int] {ro}

Total size, in bytes.

=item atime : Maybe[DateTime] {ro}

Time of last access as DateTime object.

=item mtime : Maybe[DateTime] {ro}

Time of last modification as DateTime object.

=item ctime : Maybe[DateTime] {ro}

Time of last status change as DateTime object.

=item blksize : Maybe[Int] {ro}

Block size for filesystem I/O.

=item blocks : Maybe[Int] {ro}

Number of blocks allocated.

=back

=head1 OVERLOADS

=over

=item Array dereferencing

If C<File::Stat::Moose> object is dereferenced as array it returns an array
with the same order of values as in L<perlfunc/stat> or L<perlfunc/lstat>
functions.  Attributes C<atime>, C<ctime> and C<mtime> are returned as number
values (Unix timestamp).

  $st = File::Stat::Moose->new( file => '/etc/passwd' );
  @st = @$st;

=back

=head1 CONSTRUCTORS

=over

=item new( I<args> : Hash ) : Self

Creates the C<File::Stat::Moose> object and calls C<update> method.

If the I<file> is symlink and the I<follow> is true, it will check the file
that it refers to.  If the I<follow> is false, it will check the symlink
itself.

  $st = File::Stat::Moose->new( file => '/etc/cdrom', follow => 1 );
  print "Device: ", $st->rdev, "\n";  # check real device, not symlink

The object is dereferenced in array context to the array reference which
contains the same values as L<perlfunc/stat> function output.

  $st = File::Stat::Moose->new( file => '/etc/passwd' );
  print "Size: ", $st->size, "\n";  # object's attribute
  print "Size: ", $st->[7], "\n";   # array dereference

=back

=head1 METHODS

=over

=item stat(I<>) : Self

Updates all attributes which represent status of file.

Calls L<perlfunc/stat> function if C<follow> method is true value or
L<perlfunc/lstat> function otherwise.

=back

=head1 FUNCTIONS

=over

=item stat( I<file> : Str|FileHandle|CacheFileHandle|OpenHandle = $_ ) : Self|Array

Calls stat on given I<file>.  If the I<file> is undefined, the C<$_> variable
is used instead.

If it is called in array context, it returns an array with the same values as
for output of core C<stat> function.

  use File::Stat::Moose 'stat';
  $_ = '/etc/passwd';
  @st = stat;
  print "Size: $st[7]\n";

If it is called with scalar context, it returns the C<File::Stat::Moose>
object.

  use File::Stat::Moose 'stat';
  $st = stat '/etc/passwd';
  @st = @$st;

=item lstat( I<file> : Str|FileHandle|CacheFileHandle|OpenHandle = $_ ) : Self|Array

It is identical to C<stat>, except that if I<file> is a symbolic link, then
the link itself is checked, not the file that it refers to.

  use File::Stat::Moose 'lstat';
  @st = lstat '/etc/motd';

=back

=head1 BUGS

C<stat> and C<lstat> functions does not accept special handler C<_> written
as bareword.  You have to use it as a glob reference C<\*_>.

  use File::Stat::Moose 'stat';
  stat "/etc/passwd";  # set the special filehandle _
  @st = stat _;        # does not work
  @st = stat \*_;      # ok

=head1 PERFORMANCE

The L<File::Stat::Moose> module is 1.7 times slower than L<File::stat>
module and 10 times slower than L<perlfunc/stat> function.  The function
interface is 1.5 times slower than OO interface.

=head1 SEE ALSO

L<Exception::Base>, L<MooseX::Types::OpenHandle>,
L<MooseX::Types::CacheFileHandle>, L<Moose>, L<File::stat>, L<DateTime>.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (C) 2007, 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
