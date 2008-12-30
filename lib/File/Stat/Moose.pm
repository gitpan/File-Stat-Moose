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
use warnings;

our $VERSION = 0.04;

use Moose;

use MooseX::Types::OpenHandle;
use MooseX::Types::CacheFileHandle;

use constant::boolean;
use Scalar::Util 'weaken';
use DateTime;


use Exception::Base (
    '+ignore_package'     => [ __PACKAGE__, 'Sub::Exporter', qr/^Moose::/, qr/^Class::MOP::/ ],
);
use Exception::Argument;
use Exception::IO;


use overload (
    '@{}' => '_deref_array',
    fallback => 1
);


use Sub::Exporter -setup => {
    exports => [

        # Get file status
        stat => sub {
            sub (;*) {
                my $st = __PACKAGE__->new(
                    file => (defined $_[0] ? $_[0] : $_),
                    follow => 1
                );
                return wantarray ? @{ $st } : $st;
            };
        },

        # Get link status
        lstat => sub {
            sub (;*) {
                my $st = __PACKAGE__->new(
                    file => (defined $_[0] ? $_[0] : $_)
                );
                return wantarray ? @{ $st } : $st;
            };
        },

    ],
    groups => { all => [ qw{ stat lstat } ] },
};


# File which is checked with stat
has file => (
    is       => 'rw',
    isa      => 'Str | FileHandle | CacheFileHandle | OpenHandle',
);

# Follow symlink or read symlink itself
has follow => (
    is       => 'rw',
    isa      => 'Bool',
    default  => FALSE,
);

# Speeds up stat on Win32
has sloppy => (
    is       => 'rw',
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
            lazy     => 1,
            default  => sub {
                return '' if not exists $_[0]->{"_${attr}_epoch"};
                defined $_[0]->{"_${attr}_epoch"}
                ? DateTime->from_epoch( epoch => $_[0]->{"_${attr}_epoch"} )
                : undef
            },
            reader   => $attr,
        );

    };
};


# Constructor calls stat method if necessary
sub BUILD {
    my ($self, $params) = @_;

    # Call stat or lstat if file was provided
    if (defined $self->{file}) {
        $self->{follow} ? $self->stat : $self->lstat;
    };
    
    return TRUE;
};


# Get file status
sub stat {
    my ($self, $file) = @_;

    Exception::Argument->throw( message => 'Usage: $st->stat()' ) if @_ > 1;

    # Clean lazy attributes
    delete @{$self}{ qw{ atime mtime ctime } };

    local ${^WIN32_SLOPPY_STAT} = $self->{sloppy};

    @{$self}{ qw{ dev ino mode nlink uid gid rdev size _atime_epoch _mtime_epoch _ctime_epoch blksize blocks } }
    = map { defined $_ && $_ eq '' ? undef : $_ }
      CORE::stat $self->{file} or Exception::IO->throw( message => 'Cannot stat' );

    return $self;
};


# Get link status
sub lstat {
    my ($self, $file) = @_;

    Exception::Argument->throw( message => 'Usage: $st->lstat()' ) if @_ > 1;

    # Clean lazy attributes
    delete @{$self}{ qw{ atime mtime ctime } };

    local ${^WIN32_SLOPPY_STAT} = $self->{sloppy};

    no warnings 'io';  # lstat() on filehandle
    @{$self}{ qw{ dev ino mode nlink uid gid rdev size _atime_epoch _mtime_epoch _ctime_epoch blksize blocks } }
    = map { defined $_ && $_ eq '' ? undef : $_ }
      CORE::lstat $self->{file} or Exception::IO->throw( message => 'Cannot lstat' );

    return $self;
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
 +file : Str|FileHandle|CacheFileHandle|OpenHandle {rw}
 +follow : Bool {rw}                
 +sloppy : Bool {rw}                
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
 +stat() : Self
 +lstat() : Self
 <<utility>> +stat( file : Str|FileHandle|CacheFileHandle|OpenHandle = $_ ) : Self|Array
 <<utility>> +lstat( file : Str|FileHandle|CacheFileHandle|OpenHandle = $_ ) : Self|Array
 -_deref_array() : ArrayRef {overload="@{}"}
                                                                                         ]

[File::Stat::Moose] ---> <<exception>> [Exception::Argument] [Exception::IO]

=end umlwiki

=head1 IMPORTS

By default, the class does not export its symbols.

=over

=item use File::Stat::Moose 'stat', 'lstat';

Imports C<stat> and/or C<lstat> functions.

=item use File::Stat::Moose ':all';

Imports all available symbols.

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

=item file : Str|FileHandle|CacheFileHandle|OpenHandle {rw}

Contains the file for check.  The attribute can hold file name or file handler
or IO object.

=item follow : Bool {rw}

If the value is true and the I<file> for check is symlink, then follows it
than checking the symlink itself.

=item sloppy : Bool {rw}

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

  $st = File::Stat::Moose->new;
  $st->file( '/etc/passwd' );
  @st = @$st;

=back

=head1 CONSTRUCTORS

=over

=item new( I<args> : Hash ) : Self

Creates the C<File::Stat::Moose> object.

  $st = File::Stat::Moose->new;
  $st->file( '/etc/passwd' );
  print "Size: ", $st->size, "\n";

The C<new> constructor calls C<stat> method if the I<file> attribute is
defined and I<follow> attribute is a true value or calls C<lstat> method if
the I<file> attribute is defined and I<follow> attribute is not a true value.

If the I<file> is symlink and the I<follow> is true, it will check the file
that it refers to.  If the I<follow> is false, it will check the symlink
itself.

  $st = File::Stat::Moose->new( file=>'/etc/cdrom', follow=>1 );
  print "Device: ", $st->rdev, "\n";  # check real device, not symlink

The object is dereferenced in array context to the array reference which
contains the same values as L<perlfunc/stat> function output.

  $st = File::Stat::Moose->new( file=>'/etc/passwd' );
  print "Size: ", $st->size, "\n";  # object's attribute
  print "Size: ", $st->[7], "\n";   # array dereference

=back

=head1 METHODS

=over

=item stat(I<>) : Self

Calls stat on the file which has been set with C<new> constructor.  It returns
the object reference.

  $st = File::Stat::Moose->new;
  $st->file( '/etc/passwd' );
  print "Size: ", $st->stat->size, "\n";

=item lstat(I<>) : Self

It is identical to C<stat>, except that if I<file> is a symbolic link, then
the link itself is checked, not the file that it refers to.

  $st = File::Stat::Moose->new;
  $st->file( '/dev/cdrom' );
  print "Size: ", $st->lstat->mode, "\n";

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

If it is called with scalar context, it returns the C<File::Stat::Moose> object.

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

Piotr Roszatycki E<lt>dexter@debian.orgE<gt>

=head1 LICENSE

Copyright (C) 2007, 2008 by Piotr Roszatycki E<lt>dexter@debian.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
