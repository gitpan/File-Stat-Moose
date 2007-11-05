package File::Stat::MooseTest;

use strict;
use warnings;

use base 'Test::Unit::TestCase';

use File::Stat::Moose;
use Exception::Base 'try', 'catch';

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

sub test_File_Stat_Moose___isa {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    $self->assert_not_null($obj);
    $self->assert($obj->isa('File::Stat::Moose'));
}

sub test_File_Stat_Moose_new {
    my $self = shift;
    my $obj = File::Stat::Moose->new(file => $file);
    $self->assert_not_null($obj);
    $self->assert($obj->isa('File::Stat::Moose'));
    $self->assert_not_equals(0, $obj->size);
}

sub test_File_Stat_Moose_new_symlink {
    return unless $symlink;

    my $self = shift;
    my $obj1 = File::Stat::Moose->new(file => $symlink);
    $self->assert_not_null($obj1);
    $self->assert($obj1->isa('File::Stat::Moose'));
    $self->assert_not_equals(0, $obj1->size);

    my $obj2 = File::Stat::Moose->new(file => $symlink, follow => 1);
    $self->assert_not_null($obj2);
    $self->assert($obj2->isa('File::Stat::Moose'));
    $self->assert_not_equals(0, $obj2->size);

    $self->assert_not_equals($obj1->ino, $obj2->ino);
}

sub test_File_Stat_Moose_new_exception_constraint {
    my $self = shift;
    try eval {
        my $obj = File::Stat::Moose->new(file => undef);
    };
    catch my $e1;
    $self->assert_matches(qr/does not pass the type constraint/, $e1->eval_error);

    try eval {
        my $obj = File::Stat::Moose->new(file => [1, 2, 3]);
    };
    catch my $e2;
    $self->assert_matches(qr/does not pass the type constraint/, $e2->eval_error);

    try eval {
        my $obj = File::Stat::Moose->new(file => (bless {} => 'My::Class'));
    };
    catch my $e3;
    $self->assert_matches(qr/does not pass the type constraint/, $e3->eval_error);

    try eval {
        my $obj = File::Stat::Moose->new(file => $file, follow => \1);
    };
    catch my $e4;
    $self->assert_matches(qr/does not pass the type constraint/, $e4->eval_error);
}

sub test_File_Stat_Moose_new_exception_io {
    my $self = shift;
    try eval {
        my $obj = File::Stat::Moose->new(file => $notexistant);
    };
    catch my $e;
    $self->assert($e->isa('Exception::IO'));
}

sub test_File_Stat_Moose__deref_array {
    my $self = shift;
    my $obj = File::Stat::Moose->new(file => $file);
    $self->assert_not_null($obj);
    $self->assert($obj->isa('File::Stat::Moose'));
    $self->assert_not_equals(0, $obj->[7]);
    $self->assert_equals(13, scalar @$obj);
}

sub test_File_Stat_Moose_stat {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    $self->assert_not_null($obj);
    $self->assert($obj->isa('File::Stat::Moose'));
    $self->assert_null($obj->size);
    
    $self->assert_not_null($obj->stat($file));
    $self->assert_not_equals(0, $obj->size);

    $_ = $notexistant;
    try eval { $obj->stat; };
    catch my $e;
    $self->assert($e->isa('Exception::IO'));
}

sub test_File_Stat_Moose_lstat {
    my $self = shift;
    my $obj = File::Stat::Moose->new;
    $self->assert_not_null($obj);
    $self->assert($obj->isa('File::Stat::Moose'));
    $self->assert_null($obj->size);
    
    $self->assert_not_null($obj->lstat($file));
    $self->assert_not_equals(0, $obj->size);

    $_ = $notexistant;
    try eval { $obj->lstat; };
    catch my $e;
    $self->assert($e->isa('Exception::IO'));
}

sub test_File_Stat_Moose_stat_static_method {
    my $self = shift;
    my $obj = File::Stat::Moose->stat($file);
    $self->assert_not_null($obj);
    $self->assert($obj->isa('File::Stat::Moose'));
    $self->assert_not_equals(0, $obj->size);

    try eval { File::Stat::Moose->stat($notexistant); };
    catch my $e;
    $self->assert($e->isa('Exception::IO'));
}

1;
