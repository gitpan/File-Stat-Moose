package File::Stat::MooseTest;

use strict;
use warnings;

use base 'Test::Unit::TestCase';

use File::Stat::Moose;
use Exception::Base;
use Exception::Died;

use File::Spec;
use File::Temp 'tmpnam';

our ($file, $symlink, $notexistant);

sub set_up {
    $file = __FILE__;
    $symlink = tmpnam();
    $notexistant = '/MooseTestNotExistant';

    eval { symlink File::Spec->rel2abs($file), $symlink };
    $symlink = undef if $@;
}

sub tear_down {
    unlink $symlink if $symlink;
}

sub test___isa {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    $self->assert_not_null($obj);
    $self->assert($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
}

sub test_new {
    my $self = shift;
    my $obj = File::Stat::Moose->new(file => $file);
    $self->assert_not_null($obj);
    $self->assert($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    $self->assert_not_equals(0, $obj->size);
}

sub test_new_symlink {
    return unless $symlink;

    my $self = shift;
    my $obj1 = File::Stat::Moose->new(file => $symlink);
    $self->assert_not_null($obj1);
    $self->assert($obj1->isa("File::Stat::Moose"), '$obj1->isa("File::Stat::Moose")');
    $self->assert_not_equals(0, $obj1->size);

    my $obj2 = File::Stat::Moose->new(file => $symlink, follow => 1);
    $self->assert_not_null($obj2);
    $self->assert($obj2->isa("File::Stat::Moose"), '$obj2->isa("File::Stat::Moose")');
    $self->assert_not_equals(0, $obj2->size);

    $self->assert_not_equals($obj1->ino, $obj2->ino);
}

sub test_new_exception_constraint {
    my $self = shift;
    eval {
        my $obj = File::Stat::Moose->new(file => undef);
    };
    my $e1 = Exception::Died->catch;
    $self->assert_matches(qr/does not pass the type constraint/, $e1->eval_error);

    eval {
        my $obj = File::Stat::Moose->new(file => [1, 2, 3]);
    };
    my $e2 = Exception::Died->catch;
    $self->assert_matches(qr/does not pass the type constraint/, $e2->eval_error);

    eval {
        my $obj = File::Stat::Moose->new(file => (bless {} => 'My::Class'));
    };
    my $e3 = Exception::Died->catch;
    $self->assert_matches(qr/does not pass the type constraint/, $e3->eval_error);

    eval {
        my $obj = File::Stat::Moose->new(file => $file, follow => \1);
    };
    my $e4 = Exception::Died->catch;
    $self->assert_matches(qr/does not pass the type constraint/, $e4->eval_error);
}

sub test_new_exception_io {
    my $self = shift;
    eval {
        my $obj = File::Stat::Moose->new(file => $notexistant);
    };
    my $e = Exception::Base->catch;
    $self->assert_equals('Exception::IO', ref $e);
}

sub test___deref_array {
    my $self = shift;
    my $obj = File::Stat::Moose->new(file => $file);
    $self->assert_not_null($obj);
    $self->assert($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    $self->assert_not_equals(0, $obj->[7]);
    $self->assert_equals(13, scalar @$obj);
}

sub test_stat {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    $self->assert_not_null($obj);
    $self->assert($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    $self->assert_null($obj->size);

    $self->assert_not_null($obj->stat($file));
    $self->assert_not_equals(0, $obj->size);

    $_ = $notexistant;
    eval { $obj->stat; };
    my $e = Exception::Base->catch;
    $self->assert_equals('Exception::IO', ref $e);
}

sub test_lstat {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    $self->assert_not_null($obj);
    $self->assert($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    $self->assert_null($obj->size);

    $self->assert_not_null($obj->lstat($file));
    $self->assert_not_equals(0, $obj->size);

    $_ = $notexistant;
    eval { $obj->lstat; };
    my $e = Exception::Base->catch;
    $self->assert_equals('Exception::IO', ref $e);
}

sub test_stat_static_method {
    my $self = shift;
    my $obj = File::Stat::Moose->stat($file);
    $self->assert_not_null($obj);
    $self->assert($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    $self->assert_not_equals(0, $obj->size);

    eval { File::Stat::Moose->stat($notexistant); };
    my $e1 = Exception::Base->catch;
    $self->assert_equals('Exception::IO', ref $e1);

    eval { File::Stat::Moose->stat($file, 'badargument'); };
    my $e2 = Exception::Base->catch;
    $self->assert_equals('Exception::Argument', ref $e2);
}

sub test_lstat_static_method {
    my $self = shift;
    my $obj = File::Stat::Moose->lstat($file);
    $self->assert_not_null($obj);
    $self->assert($obj->isa("File::Stat::Moose"), '$obj->isa("File::Stat::Moose")');
    $self->assert_not_equals(0, $obj->size);

    eval { File::Stat::Moose->lstat($notexistant); };
    my $e1 = Exception::Base->catch;
    $self->assert_equals('Exception::IO', ref $e1);

    eval { File::Stat::Moose->lstat($file, 'badargument'); };
    my $e2 = Exception::Base->catch;
    $self->assert_equals('Exception::Argument', ref $e2);
}

1;
