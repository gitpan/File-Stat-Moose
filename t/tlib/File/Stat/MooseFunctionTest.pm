package File::Stat::MooseFunctionTest;

use strict;
use warnings;

use base 'Test::Unit::TestCase';

use File::Stat::Moose ':all';
use Exception::Base;

use File::Spec;
use File::Temp 'tmpnam';

{
    package File::Stat::MooseFunctionTest::Test1;

    use File::Stat::Moose 'lstat';
}

{
    package File::Stat::MooseFunctionTest::Test2;

    use File::Stat::Moose;
}

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

sub test_import {
    my $self = shift;

    $self->assert_not_null(prototype 'File::Stat::MooseFunctionTest::stat');
    $self->assert_not_null(prototype 'File::Stat::MooseFunctionTest::lstat');

    $self->assert_null(prototype 'File::Stat::MooseFunctionTest::Test1::stat');
    $self->assert_not_null(prototype 'File::Stat::MooseFunctionTest::Test1::lstat');

    $self->assert_null(prototype 'File::Stat::MooseFunctionTest::Test2::stat');
    $self->assert_null(prototype 'File::Stat::MooseFunctionTest::Test2::lstat');
}

sub test_stat {
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

    eval { stat($notexistant); };
    my $e = Exception::Base->catch;
    $self->assert_equals('Exception::IO', ref $e);
}

sub test_lstat {
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

    eval { lstat($notexistant); };
    my $e = Exception::Base->catch;
    $self->assert_equals('Exception::IO', ref $e);
}

sub test_lstat_symlink {
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
