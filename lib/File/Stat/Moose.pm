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

our $VERSION = 0.03;

use Moose;

use MooseX::Types::OpenHandle;
use MooseX::Types::CacheFileHandle;

use Scalar::Util 'weaken';
use DateTime;


# File which is checked with stat
has file => (
    is       => 'rw',
    isa      => 'Str | FileHandle | CacheFileHandle | OpenHandle',
);

# Follow symlink or read symlink itself
has follow => (
    is       => 'rw',
    isa      => 'Bool',
);

# Numeric informations about a file
has [ qw{ dev ino mode nlink uid gid rdev size blksize blocks } ] => (
    is       => 'ro',
    isa      => 'Int',
);

{
    foreach my $attr ( qw{ atime mtime ctime } ) {

        # Numeric informations about a file (time as unix timestamp)
        has "_${attr}_epoch" => (
            isa      => 'Int',
        );

        # Time as DateTime object (lazy evaluationed)
        has $attr => (
            is       => 'ro',
            isa      => 'DateTime',
            lazy     => 1,
            default  => sub { DateTime->from_epoch( epoch => $_[0]->{"_${attr}_epoch"} ) },
            reader   => $attr,
        );

    };
};


use Exception::Base (
    '+ignore_package'     => [ __PACKAGE__, 'Sub::Exporter', qr/^Moose::/, qr/^Class::MOP::/ ],
    'Exception::Argument' => { isa => 'Exception::Base' },
    'Exception::IO'       => { isa => 'Exception::System' },
);


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


# Constructor calls stat method if necessary
sub BUILD {
    my ($self, $params) = @_;

    # Call stat or lstat if file was provided
    if (defined $self->{file}) {
        $self->{follow} ? $self->stat : $self->lstat;
    };
    
    return;
};


# Get file status
sub stat {
    my ($self, $file) = @_;

    # Called as static method
    if (not ref $self) {
        Exception::Argument->throw( message => 'Usage: ' . __PACKAGE__ . '->lstat(FILE)' ) if @_ != 2;
        return $self->new( file => $file, follow => 1 );
    };

    Exception::Argument->throw( message => 'Usage: $st->stat()' ) if @_ > 1;

    # Clean lazy attributes
    delete @{$self}{ qw{ atime mtime ctime } };

    @{$self}{ qw{ dev ino mode nlink uid gid rdev size _atime_epoch _mtime_epoch _ctime_epoch blksize blocks } }
    = CORE::stat $self->{file} or Exception::IO->throw( message => 'Cannot stat' );

    return $self;
}


# Get link status
sub lstat {
    my ($self, $file) = @_;

    # Called as static method
    if (not ref $self) {
        Exception::Argument->throw( message => 'Usage: ' . __PACKAGE__ . '->lstat(FILE)' ) if @_ != 2;
        return $self->new( file => $file );
    };

    Exception::Argument->throw( message => 'Usage: $st->lstat()' ) if @_ > 1;

    # Clean lazy attributes
    delete @{$self}{ qw{ atime mtime ctime } };

    no warnings 'io';  # lstat() on filehandle
    @{$self}{ qw{ dev ino mode nlink uid gid rdev size _atime_epoch _mtime_epoch _ctime_epoch blksize blocks } }
    = CORE::lstat $self->{file} or Exception::IO->throw( message => 'Cannot lstat' );

    return $self;
}


# Array dereference
sub _deref_array {
    my ($self) = @_;
    return [ @{$self}{ qw{ dev ino mode nlink uid gid rdev size _atime_epoch _mtime_epoch _ctime_epoch blksize blocks } } ];
}


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
 Exception::IO       <<exception>>
 Exception::Argument <<exception>>
 OpenHandle          <<type>
 CacheFileHandle     <<type>>     ]

[File::Stat::Moose {=}] ---> <<use>> [Exception::Base {=}] [Sub::Exporter {=}] [overload {=}]

[File::Stat::Moose {=}] ---> <<use>> [Moose {=}]

[MooseX::Types::OpenHandle {=}] ---> <<use>> [Moose::Util::TypeConstraints {=}]

[MooseX::Types::CacheFileHandle {=}] ---> <<use>> [Moose::Util::TypeConstraints {=}]

[<<exception>> Exception::IO] ---|> [<<exception>> Exception::System]

[<<exception>> Exception::Argument] ---|> [<<exception>> Exception::Base]

[<<type>> OpenHandle] ---|> [<<type>> Ref]

[<<type>> CacheFileHandle] ---|> [<<type>> GlobRef]

= Class Diagram =

[                            File::Stat::Moose
 ---------------------------------------------------------------------------
 +file : Str|FileHandle|CacheFileHandle|OpenHandle                     {new}
 +follow : Bool                                                        {new}
 +dev : Int
 +ino : Int
 +mode : Int
 +nlink : Int
 +uid : Int
 +gid : Int
 +rdev : Int
 +size : Int
 +atime : DateTime                                                    {lazy}
 +mtime : DateTime                                                    {lazy}
 +ctime : DateTime                                                    {lazy}
 +blksize : Int
 +blocks : Int
 #_atime_epoch : Int
 #_mtime_epoch : Int
 #_ctime_epoch : Int
 ---------------------------------------------------------------------------
 +stat( file : Str|FileHandle|CacheFileHandle|OpenHandle = $_ )
 +lstat( file : Str|FileHandle|CacheFileHandle|OpenHandle = $_ )
 <<utility>> +stat( file : Str|FileHandle|CacheFileHandle|OpenHandle = $_ )
 <<utility>> +lstat( file : Str|FileHandle|CacheFileHandle|OpenHandle = $_ )
 -_deref_array() : ArrayRef                                {overload="@{}"} ]

=end umlwiki

=head1 EXCEPTIONS

=over

=item Exception::Argument

Thrown whether a methods is called with wrong arguments.

=item Exception::IO

Thrown whether an IO error is occurred.

=back

=head1 IMPORTS

By default, the class does not export its symbols.

=over

=item use File::Stat::Moose 'stat', 'lstat';

Imports C<stat> and/or C<lstat> functions.

=item use File::Stat::Moose ':all';

Imports all available symbols.

=back

=head1 ATTRIBUTES

=over

=item file (rw, new)

Contains the file for check.  The attribute can hold file name or file handler
or IO object.

=item follow (rw, new)

If the value is true and the I<file> for check is symlink, then follow it
than checking the symlink itself.

=item dev (ro)

ID of device containing file.

=item ino (ro)

inode number.

=item mode (ro)

Unix mode for file.

=item nlink (ro)

Number of hard links.

=item uid (ro)

User ID of owner.

=item gid (ro)

Group ID of owner.

=item rdev (ro)

Device ID (if special file).

=item size (ro)

Total size, in bytes.

=item atime (ro)

Time of last access as DateTime object.

=item mtime (ro)

Time of last modification as DateTime object.

=item ctime (ro)

Time of last status change as DateTime object.

=item blksize (ro)

Blocksize for filesystem I/O.

=item blocks (ro)

Number of blocks allocated.

=back

=head1 CONSTRUCTORS

=over

=item new

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

=item File::Stat::Moose->stat(I<file>)

Creates the C<File::Stat::Moose> object and calls L<perlfunc/stat> function on
given I<file>.  If the I<file> is undefined, the <$_> variable is used
instead.  It returns the object reference.

  $st = File::Stat::Moose->stat( '/etc/passwd' );
  print "Size: ", $st->size, "\n";
  @st = @{ File::Stat::Moose->stat( '/etc/passwd' ) };

=item File::Stat::Moose->lstat(I<file>)

Creates the C<File::Stat::Moose> object and calls L<perlfunc/lstat> function on
given I<file>.  If the I<file> is undefined, the <$_> variable is used
instead.  It returns the object reference.

  @st = @{ File::Stat::Moose->lstat( '/dev/stdin' ) };

=back

=head1 METHODS

=over

=item $st->stat

Calls stat on the file which has beed set with C<new> constructor.  It returns
the object reference.

  $st = File::Stat::Moose->new;
  $st->file( '/etc/passwd' );
  print "Size: ", $st->stat->size, "\n";

=item $st->lstat

It is identical to C<stat>, except that if I<file> is a symbolic link, then
the link itself is checked, not the file that it refers to.

  $st = File::Stat::Moose->new;
  $st->file( '/dev/cdrom' );
  print "Size: ", $st->lstat->mode, "\n";

=back

=head1 FUNCTIONS

=over

=item stat([I<file>])

Calls stat on given I<file>.  If the I<file> is undefined, the <$_> variable
is used instead.

If it is called as function or static method in array context, it returns an
array with the same values as for output of core C<stat> function.

  use File::Stat::Moose 'stat';
  $_ = '/etc/passwd';
  @st = stat;
  print "Size: $st[7]\n";

If it is called with scalar context, it returns the File::Stat::Moose object.

  use File::Stat::Moose 'stat';
  $st = stat '/etc/passwd';
  @st = @$st;

=item lstat([I<file>])

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
