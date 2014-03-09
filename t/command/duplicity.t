use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/lib';

use App::rmachine::command::duplicity;
use App::rmachine::command_runner;
use TestUtils;

subtest 'detect when source changed' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest = TestUtils->prepare_tree();

    my $command = _build_command(
        source => $source,
        dest   => "file:///$dest",
    );

    ok $command->has_source_changed;
};

subtest 'detect when source has not changed' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest = TestUtils->prepare_tree();

    my $command = _build_command(
        source => $source,
        dest   => "file:///$dest",
    );

    $command->run;

    $command = _build_command(
        source => $source,
        dest   => "file:///$dest",
    );

    ok !$command->has_source_changed;
};

subtest 'encrypt files' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest = TestUtils->prepare_tree();

    my $command = _build_command(
        source => $source,
        dest   => "file:///$dest",
    );

    $command->run;

    my $result = TestUtils->read_tree($dest);
    ok grep { /manifest/ } keys %$result;
    ok grep { /sigtar/ } keys %$result;
};

sub _build_command {
    my (%params) = @_;

    my $command_runner = App::rmachine::command_runner->new;

    return App::rmachine::command::duplicity->new(
        env            => 'PASSPHRASE=bar',
        command_runner => $command_runner,
        %params
    );
}

done_testing;
