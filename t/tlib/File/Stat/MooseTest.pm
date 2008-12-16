package File::Stat::MooseTest;

use strict;
use warnings;

use base 'Test::Unit::TestCase';
use Test::Assert ':all';

use File::Stat::Moose;

use Exception::Base;

use File::Spec;
use File::Temp ();

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
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    assert_not_null($obj);
    assert_true($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    assert_null($obj->size);
};

sub test_new_file {
    my $self = shift;
    my $obj = File::Stat::Moose->new(file => $file);
    assert_not_null($obj);
    assert_true($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    assert_not_equals(0, $obj->size);
};

sub test_new_symlink {
    return unless $symlink;

    my $self = shift;
    my $obj1 = File::Stat::Moose->new(file => $symlink);
    assert_not_null($obj1);
    assert_true($obj1->isa("File::Stat::Moose"), '$obj1->isa("File::Stat::Moose")');
    assert_not_equals(0, $obj1->size);

    my $obj2 = File::Stat::Moose->new(file => $symlink, follow => 1);
    assert_not_null($obj2);
    assert_true($obj2->isa("File::Stat::Moose"), '$obj2->isa("File::Stat::Moose")');
    assert_not_equals(0, $obj2->size);

    assert_not_equals($obj1->ino, $obj2->ino);
}

sub test_new_exception_constraint {
    my $self = shift;
    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new(file => undef);
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new(file => [1, 2, 3]);
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new(file => (bless {} => 'My::Class'));
    } );

    assert_raises( qr/does not pass the type constraint/, sub {
        my $obj = File::Stat::Moose->new(file => $file, follow => \1);
    } );
}

sub test_new_exception_io {
    my $self = shift;
    assert_raises( ['Exception::IO'], sub {
        my $obj = File::Stat::Moose->new(file => $notexistant);
    } );
};

sub test__deref_array {
    my $self = shift;
    my $obj = File::Stat::Moose->new(file => $file);
    assert_not_null($obj);
    assert_true($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    assert_equals(13, scalar @$obj);
    {
        foreach my $value (@$obj) {
            assert_matches(qr/^\d+$/, $value);
        };
    };
    assert_not_equals(0, $obj->[7]);
};

sub test_stat {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    assert_not_null($obj);
    assert_true($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_null($obj->$attr);
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_raises( qr/is not one of the allowed types/, sub { $obj->$attr } );
        };
    };

    $obj->file($file);
    assert_equals($file, $obj->file);
    $obj->follow(1);
    assert_equals(1, $obj->follow);

    assert_not_null($obj->stat);
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^\d+$/, $obj->$attr);
        };
    };
    assert_not_equals(0, $obj->size);
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_equals('DateTime', ref $obj->$attr);
        };
    };
};

sub test_stat_failure {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    assert_not_null($obj);

    $obj->file($notexistant);
    $obj->follow(1);

    assert_raises( ['Exception::IO'], sub { $obj->stat } );

    assert_raises( ['Exception::Argument'], sub { $obj->stat('badargument') } );
};

sub test_lstat {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    assert_not_null($obj);
    assert_true($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_null($obj->$attr);
        };
    };
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_raises( qr/is not one of the allowed types/, sub { $obj->$attr } );
        };
    };

    $obj->file($file);
    assert_equals($file, $obj->file);
    $obj->follow(0);
    assert_equals(0, $obj->follow);

    assert_not_null($obj->lstat);
    {
        foreach my $attr (qw{ dev ino mode nlink uid gid rdev size blksize blocks }) {
            assert_matches(qr/^\d+$/, $obj->$attr);
        };
    };
    assert_not_equals(0, $obj->size);
    {
        foreach my $attr (qw { atime mtime ctime }) {
            assert_equals('DateTime', ref $obj->$attr);
        };
    };
};

sub test_lstat_failure {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    assert_not_null($obj);

    $obj->file($notexistant);
    $obj->follow(0);

    assert_raises( ['Exception::IO'], sub { $obj->lstat } );

    assert_raises( ['Exception::Argument'], sub { $obj->lstat('badargument') } );
};

sub test_stat_static_method {
    my $self = shift;
    my $obj = File::Stat::Moose->stat($file);
    assert_not_null($obj);
    assert_true($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    assert_not_equals(0, $obj->size);
};

sub test_stat_static_method_failure {
    my $self = shift;
    assert_raises( ['Exception::IO'], sub {
        File::Stat::Moose->stat($notexistant);
    } );
    assert_raises( ['Exception::Argument'], sub {
        File::Stat::Moose->stat();
    } );
    assert_raises( ['Exception::Argument'], sub {
        File::Stat::Moose->stat($file, 'badargument');
    } );
};

sub test_lstat_static_method {
    my $self = shift;
    my $obj = File::Stat::Moose->lstat($file);
    assert_not_null($obj);
    assert_true($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    assert_not_equals(0, $obj->size);
}

sub test_lstat_static_method_failure {
    my $self = shift;
    assert_raises( ['Exception::IO'], sub {
        File::Stat::Moose->lstat($notexistant);
    } );
    assert_raises( ['Exception::Argument'], sub {
        File::Stat::Moose->lstat();
    } );
    assert_raises( ['Exception::Argument'], sub {
        File::Stat::Moose->lstat($file, 'badargument');
    } );
};

1;
