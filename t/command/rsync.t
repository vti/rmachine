use strict;
use warnings;

use Test::More;

use lib 't/lib';

use App::rmachine::command_runner;
use App::rmachine::command::rsync;
use TestUtils;

subtest 'detect when source changed' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest = TestUtils->prepare_tree();

    my $command = _build_command(
        source => $source,
        dest   => $dest,
    );

    ok $command->has_source_changed;
};

subtest 'detect when source has not changed' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest   = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');

    my $command = _build_command(
        source => $source,
        dest   => $dest,
    );

    ok !$command->has_source_changed;
};

subtest 'sync directories' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest = TestUtils->prepare_tree();

    my $command = _build_command(
        source => $source,
        dest   => $dest,
    );

    $command->run;

    is_deeply(TestUtils->read_tree($dest), {foo => 1, bar => 1});
};

subtest 'not sync excluded files' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest = TestUtils->prepare_tree();

    my $command = _build_command(
        source  => $source,
        dest    => $dest,
        exclude => 'bar'
    );

    $command->run;

    is_deeply(TestUtils->read_tree($dest), {foo => 1});
};

sub _build_command {
    my (%params) = @_;

    my $command_runner = App::rmachine::command_runner->new;

    return App::rmachine::command::rsync->new(
        command_runner => $command_runner,
        %params
    );
}

done_testing;
