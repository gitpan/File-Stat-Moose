#!/usr/bin/perl -c

package File::Stat::Moose;
use 5.006;
our $VERSION = 0.01_02;

=head1 NAME

File::Stat::Moose - Status info for a file - Moose-based

=head1 SYNOPSIS

  use IO::File;
  use File::Stat::Moose;
  $fh = new IO::File '/etc/passwd';
  $st = new File::Stat::Moose file=>$fh;
  print "Size: ", $st->size, "\n";    # named field
  print "Blocks: ". $st->[12], "\n";  # numbered field

=head1 DESCRIPTION

This class provides methods that returns status info for a file.  It is the
OO-style version of stat/lstat functions.  It also throws an exception
immediately after error is occured.

=cut


use Moose;

use Moose::Util::TypeConstraints;


subtype 'IO'
    => as 'Object'
    => where { defined $_
            && Scalar::Util::reftype($_) eq 'GLOB'
            && Scalar::Util::openhandle($_) }
    => optimize_as { defined $_[0]
                  && Scalar::Util::reftype($_[0]) eq 'GLOB'
                  && Scalar::Util::openhandle($_[0]) };

subtype 'CacheFileHandle'
    => as 'GlobRef'
    => where { defined $_
            && Scalar::Util::reftype($_) eq 'GLOB'
            && $_ == \*_ }
    => optimize_as { defined $_[0]
                  && Scalar::Util::reftype($_[0]) eq 'GLOB'
                  && $_[0] == \*_ };


has 'file' =>
    is       => 'ro',
    isa      => 'Str | FileHandle | CacheFileHandle | IO',
    weak_ref => 1;

has 'follow' =>
    is       => 'ro',
    isa      => 'Bool';

has [ qw< dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks > ] =>
    is       => 'ro';


use Exception::Base
    'Exception::Runtime'  => { isa => 'Exception::Base' },
    'Exception::BadValue' => { isa => 'Exception::Runtime' },
    'Exception::IO'       => { isa => 'Exception::System' };


use overload '@{}' => \&_deref_array,
             fallback => 1;


use Exporter (); *import = \&Exporter::import;
our @EXPORT_OK = qw< stat lstat >;
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);


# Constructor calls stat method if necessary
sub BUILD {
    my ($self, $params) = @_;

    if (defined $self->{file}) {
        $self->{follow} ? $self->stat($self->{file}) : $self->lstat($self->{file});
    }
};


# Method / function
sub stat (;*) {
    # called as function
    if (not eval { $_[0]->isa(__PACKAGE__) }) {
        my $st = __PACKAGE__->new(file => (defined $_[0] ? $_[0] : $_), follow => 1);
        return wantarray ? @{ $st } : $st;
    }

    my $self = shift;
    my $file = shift;

    $file = $_ if not defined $file;

    # called as static method
    if (not ref $self) {
        return $self->new(file => $file, follow => 1);
    }

    throw Exception::BadValue
          message => 'Usage: ' . __PACKAGE__ . '->stat(FILE)'
        if @_ > 1;

    my %stat;
    @{$self}{qw< dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks >}
        = CORE::stat $file
        or throw Exception::IO
                 message => 'Cannot stat';

    return $self;
}


# Method / function
sub lstat (;*) {
    # called as function
    if (not eval { $_[0]->isa(__PACKAGE__) }) {
        my $st = __PACKAGE__->new(file => (defined $_[0] ? $_[0] : $_));
        return wantarray ? @{ $st } : $st;
    }

    my $self = shift;
    my $file = shift;

    $file = $_ if not defined $file;

    # called as static method
    if (not ref $self) {
        return $self->new(file => $file);
    }

    throw Exception::BadValue
          message => 'Usage: ' . __PACKAGE__ . '->lstat(FILE)'
        if @_ > 1;

    my %stat;
    no warnings 'io';  # lstat() on filehandle
    @{$self}{qw< dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks >}
        = CORE::lstat $file
        or throw Exception::IO
                 message => 'Cannot lstat';

    return $self;
}


# Array dereference
sub _deref_array {
    my $self = shift;
    return [ @{$self}{qw< dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks >} ];
}


__PACKAGE__->meta->make_immutable();


1;


__END__

=for readme stop

=head1 BASE CLASSES

=over 2

=item *

L<Moose::Base>

=back

=head1 IMPORTS

By default, the class does not export its symbols.

=over

=item use File::Stat::Moose 'stat', 'lstat';

Imports B<stat> and/or B<lstat> functions.

=item use File::Stat::Moose ':all';

Imports all available symbols.

=back

=head1 FIELDS

=over

=item file (ro, weak_ref)

Contains the file for check.  The field can hold file name or file handler or
IO object.

=item follow (ro)

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

Time of last access.

=item mtime (ro)

Time of last modification.

=item ctime (ro)

Time of last status change.

=item blksize (ro)

Blocksize for filesystem I/O.

=item blocks (ro)

Number of blocks allocated.

=back

=head1 CONSTRUCTORS

=over

=item new

Creates the B<File::Stat::Moose> object and calls B<stat> method if the
I<file> field is defined and I<follow> field is a true value or calls
B<lstat> method if the I<file> field is defined and I<follow> field is not a
true value.

If the I<file> is symlink and the I<follow> is true, it will check the file
that it refers to.  If the I<follow> is false, it will check the symlink
itself.

  $st = new File::Stat::Moose file=>'/etc/cdrom', follow=>1;
  print "Device: $st->rdev\n";  # check real device, not symlink itself  

The object is dereferenced in array context to the array reference which
contains the same values as core B<stat> function output.

  $st = new File::Stat::Moose file=>'/etc/passwd';
  print "Size: $st->size\n";  # object's field
  print "Size: $st->[7]\n";   # array dereference

=item File::Stat::Moose->stat(I<file>)

Creates the B<File::Stat::Moose> object and calls B<CORE::stat> function on
given I<file>.  If the I<file> is undefined, the <$_> variable is used
instead.  It returns the object reference.

  $st = File::Stat::Moose->stat('/etc/passwd');
  print "Size: ", $st->size, "\n";
  @st = @{ File::Stat::Moose->stat('/etc/passwd') };

=item File::Stat::Moose->lstat(I<file>)

Creates the B<File::Stat::Moose> object and calls B<CORE::lstat> function on
given I<file>.  If the I<file> is undefined, the <$_> variable is used
instead.  It returns the object reference.

  @st = @{ File::Stat::Moose->lstat('/dev/stdin') };

=back

=head1 METHODS

=over

=item $st->stat([I<file>])

Calls stat on given I<file> or the file which has beed set with B<new>
constructor.  If the I<file> is undefined, the <$_> variable is used instead.
It returns the object reference.

  $st = new File::Stat::Moose;
  print "Size: ", $st->stat('/etc/passwd')->{size}, "\n";

=item $st->lstat([I<file>])

It is identical to B<stat>, except that if I<file> is a symbolic link, then
the link itself is checked, not the file that it refers to.

  $st = new File::Stat::Moose;
  print "Size: ", $st->lstat('/dev/cdrom')->{mode}, "\n";

=back

=head1 FUNCTIONS

=over

=item stat([I<file>])

Calls stat on given I<file>.  If the I<file> is undefined, the <$_> variable
is used instead.

If it is called as function or static method in array context, it returns an
array with the same values as for output of core B<stat> function.

  use File::Stat::Moose 'stat';
  $_ = '/etc/passwd';
  @st = stat;
  print "Size: $st[7]\n";

If it is called with scalar context, it returns the File::Stat::Moose object.

  use File::Stat::Moose 'stat';
  $st = stat '/etc/passwd';
  @st = @$st;

=item lstat([I<file>])

It is identical to B<stat>, except that if I<file> is a symbolic link, then
the link itself is checked, not the file that it refers to.

  use File::Stat::Moose 'lstat';
  @st = lstat '/etc/motd';

=back

=head1 BUGS

B<stat> and B<lstat> functions does not accept special handler B<_> written
as bareword.  You have to use it as a glob reference B<\*_>.

  use File::Stat::Moose 'stat';
  stat "/etc/passwd";  # set the special filehandle _
  @st = stat _;        # does not work
  @st = stat \*_;      # ok

=head1 PERFORMANCE

The L<File::Stat::Moose> module is 4 times slower than L<File::stat> module and 28 times
slower than B<CORE::stat> function.  The function interface is 4 times slower than
OO interface.

=head1 SEE ALSO

L<Exception::Base>, L<perlfunc>, L<Moose>, L<File::stat>.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki E<lt>dexter@debian.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 by Piotr Roszatycki E<lt>dexter@debian.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
