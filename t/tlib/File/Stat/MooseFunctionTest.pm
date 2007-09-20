package File::Stat::MooseFunctionTest;

use base 'Test::Unit::TestCase';

use File::Stat::Moose ':all';
use Exception::Base 'try', 'catch';

use File::Spec;
use File::Temp 'tmpnam';


package File::Stat::MooseFunctionTest::Test1;

use File::Stat::Moose 'lstat';


package File::Stat::MooseFunctionTest::Test2;

use File::Stat::Moose;


package File::Stat::MooseFunctionTest;

sub set_up {
    our $file = __FILE__;
    our $symlink = tmpnam();
    our $notexistant = '/MooseTestNotExistant';

    eval { symlink File::Spec->rel2abs($file), $symlink };
    $symlink = undef if $@;
}

sub tear_down {
    unlink $symlink if $symlink;
}

sub test_File_Stat_function_import {
    my $self = shift;

    $self->assert_not_null(prototype 'File::Stat::MooseFunctionTest::stat');
    $self->assert_not_null(prototype 'File::Stat::MooseFunctionTest::lstat');

    $self->assert_null(prototype 'File::Stat::MooseFunctionTest::Test1::stat');
    $self->assert_not_null(prototype 'File::Stat::MooseFunctionTest::Test1::lstat');

    $self->assert_null(prototype 'File::Stat::MooseFunctionTest::Test2::stat');
    $self->assert_null(prototype 'File::Stat::MooseFunctionTest::Test2::lstat');
}

sub test_File_Stat_function_Moose_stat_function {
    my $self = shift;

    my $scalar = stat($file);
    $self->assert_not_null($scalar);

    my @array1 = stat($file);
    $self->assert_not_null(@array1);
    $self->assert_equals(13, scalar @array1);

    my @array2 = stat(\*_);
    $self->assert_not_null(@array2);
    $self->assert_equals(13, scalar @array2);
    $self->assert_deep_equals(\@array1, \@array2);

    local $_ = $file;
    my @array3 = stat();
    $self->assert_not_null(@array3);
    $self->assert_equals(13, scalar @array3);
    $self->assert_deep_equals(\@array1, \@array3);

    try eval { stat($notexistant); };
    catch my $e;
    $self->assert($e->isa('Exception::IO'));
}

sub test_File_Stat_function_Moose_lstat_function {
    my $self = shift;

    my $scalar = lstat($file);
    $self->assert_not_null($scalar);

    my @array1 = lstat($file);
    $self->assert_not_null(@array1);
    $self->assert_equals(13, scalar @array1);

    my @array2 = lstat(\*_);
    $self->assert_not_null(@array2);
    $self->assert_equals(13, scalar @array2);
    $self->assert_deep_equals(\@array1, \@array2);

    local $_ = $file;
    my @array3 = lstat();
    $self->assert_not_null(@array3);
    $self->assert_equals(13, scalar @array3);
    $self->assert_deep_equals(\@array1, \@array3);

    try eval { lstat($notexistant); };
    catch my $e;
    $self->assert($e->isa('Exception::IO'));
}

sub test_File_Stat_function_Moose_lstat_function_symlink {
    return unless $symlink;

    my $self = shift;

    my $scalar = lstat($symlink);
    $self->assert_not_null($scalar);

    my @array1 = lstat($symlink);
    $self->assert_not_null(@array1);
    $self->assert_equals(13, scalar @array1);

    my @array2 = lstat(\*_);
    $self->assert_not_null(@array2);
    $self->assert_equals(13, scalar @array2);
    $self->assert_deep_equals(\@array1, \@array2);

    local $_ = $symlink;
    my @array3 = lstat();
    $self->assert_not_null(@array3);
    $self->assert_equals(13, scalar @array3);
    $self->assert_deep_equals(\@array1, \@array3);

    my @array4 = stat($symlink);
    $self->assert_not_null(@array4);
    $self->assert_equals(13, scalar @array4);
    $self->assert_not_equals($array1[1], $array4[1]);
}

1;
