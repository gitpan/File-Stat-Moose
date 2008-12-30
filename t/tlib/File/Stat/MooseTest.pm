package File::Stat::MooseTest;

use strict;
use warnings;

use parent 'Test::Unit::TestCase';
use Test::Assert ':all';

use File::Stat::Moose;

use constant::boolean;
use Exception::Base;

use File::Spec;
use File::Temp;

our ($file, $symlink, $notexistant);

sub set_up {
    $file = __FILE__;
    $symlink = File::Temp::tmpnam();
    $notexistant = '/MooseTestNotExistant';

    eval {
        symlink File::Spec->rel2abs($file), $symlink;
    };
    $symlink = undef if $@;
};

sub tear_down {
    unlink $symlink if $symlink;
};

sub test_new {
    my $obj = File::Stat::Moose->new;
    assert_isa('File::Stat::Moose', $obj);
    assert_null($obj->size);
};

sub test_new_file {
    my $obj = File::Stat::Moose->new( file => $file );
    assert_isa('File::Stat::Moose', $obj);
    assert_not_equals(0, $obj->size);
};

sub test_new_symlink {
    return unless $symlink;

    my $obj1 = File::Stat::Moose->new(file => $symlink);
    assert_isa('File::Stat::Moose', $obj1);
    assert_not_equals(0, $obj1->size);

    my $obj2 = File::Stat::Moose->new(file => $symlink, follow => 1);
    assert_isa('File::Stat::Moose', $obj2);
    assert_not_equals(0, $obj2->size);

    assert_not_equals($obj1->ino, $obj2->ino);
};

sub test_new_exception_constraint {
    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new( file => undef );
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new( file => [1, 2, 3] );
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new( file => (bless {} => 'My::Class') );
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new( file => $file, follow => \1 );
    } );
};

sub test_new_exception_io {
    assert_raises( ['Exception::IO'], sub {
        my $obj = File::Stat::Moose->new( file => $notexistant );
    } );
};

sub test__deref_array {
    my $obj = File::Stat::Moose->new( file => $file );
    assert_isa('File::Stat::Moose', $obj);
    assert_equals(13, scalar @$obj);
    {
        foreach my $i (0..12) {
            assert_matches(qr/^\d+$/, $obj->[$i], $i) if defined $obj->[$i];
        };
    };
    assert_not_equals(0, $obj->[7]);
};

sub test_stat {
    my $obj = File::Stat::Moose->new;
    assert_isa('File::Stat::Moose', $obj);
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_null($obj->$attr, $attr);
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_raises( qr/does not pass the type constraint/, sub {
                $obj->$attr;
            }, $attr );
        };
    };

    $obj->file($file);
    assert_equals($file, $obj->file);

    $obj->follow(TRUE);
    assert_true($obj->follow);

    $obj->sloppy(FALSE);
    assert_false($obj->sloppy);

    $obj->stat;
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^\d+$/, $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_isa('DateTime', $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    assert_not_equals(0, $obj->size);
};

sub test_stat_sloppy {
    my $obj = File::Stat::Moose->new;
    assert_isa('File::Stat::Moose', $obj);

    $obj->file($file);
    $obj->follow(TRUE);

    $obj->sloppy(TRUE);
    assert_true($obj->sloppy);

    $obj->stat;
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^\d+$/, $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_isa('DateTime', $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    assert_not_equals(0, $obj->size);
};

sub test_stat_failure {
    my $obj = File::Stat::Moose->new;
    assert_isa('File::Stat::Moose', $obj);

    $obj->file($notexistant);
    $obj->follow(TRUE);

    assert_raises( ['Exception::IO'], sub {
        $obj->stat;
    } );

    assert_raises( ['Exception::Argument'], sub {
        $obj->stat('badargument')
    } );
};

sub test_lstat {
    my $obj = File::Stat::Moose->new;
    assert_isa('File::Stat::Moose', $obj);
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_null($obj->$attr, $attr);
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_raises( qr/does not pass the type constraint/, sub {
                $obj->$attr
            }, $attr );
        };
    };

    $obj->file($file);
    assert_equals($file, $obj->file);

    $obj->follow(FALSE);
    assert_false($obj->follow);

    $obj->sloppy(FALSE);
    assert_false($obj->sloppy);

    $obj->lstat;
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^\d+$/, $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    assert_not_equals(0, $obj->size);
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_isa('DateTime', $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
};

sub test_lstat_sloppy {
    my $obj = File::Stat::Moose->new;
    assert_isa('File::Stat::Moose', $obj);

    $obj->file($file);
    $obj->follow(FALSE);

    $obj->sloppy(TRUE);
    assert_true($obj->sloppy);

    $obj->lstat;
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^\d+$/, $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_isa('DateTime', $obj->$attr, $attr) if defined $obj->$attr;
        };
    };
    assert_not_equals(0, $obj->size);
};

sub test_lstat_failure {
    my $obj = File::Stat::Moose->new;
    assert_isa('File::Stat::Moose', $obj);

    $obj->file($notexistant);
    $obj->follow(FALSE);

    assert_raises( ['Exception::IO'], sub {
        $obj->lstat;
    } );

    assert_raises( ['Exception::Argument'], sub {
        $obj->lstat('badargument');
    } );
};

1;
