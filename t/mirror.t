use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;

use lib 't/lib';

use App::rmachine::mirror;
use App::rmachine::command_runner;
use TestUtils;

subtest 'mirror files' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest = TestUtils->prepare_tree();

    my $action = _build_action(source => $source, dest => $dest);

    $action->run;

    my $result = TestUtils->read_tree($dest);

    is_deeply $result, {foo => 1, bar => 1};
};

subtest 'mirror single file' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest = TestUtils->prepare_tree();

    my $action = _build_action(source => "$source/foo", dest => $dest);

    $action->run;

    my $result = TestUtils->read_tree($dest);

    is_deeply $result, {foo => 1};
};

subtest 'ignore exluded' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar', bar => 'baz');
    my $dest = TestUtils->prepare_tree();

    my $action = _build_action(source => $source, dest => $dest, exclude => 'bar');

    $action->run;

    my $result = TestUtils->read_tree($dest);

    is_deeply $result, {foo => 1};
};

sub _build_action {
    my (%params) = @_;

    my $logger = Test::MonkeyMock->new;
    $logger->mock(log => sub {});

    return App::rmachine::mirror->new(
        command_runner => App::rmachine::command_runner->new,
        logger => $logger, %params
    );
}

done_testing;
