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

subtest 'log actions' => sub {
    my $source = TestUtils->prepare_tree();
    my $dest = TestUtils->prepare_tree();

    my $output = '';
    my $logger = Test::MonkeyMock->new;
    $logger->mock(log => sub { shift; $output .= join '|', @_ });
    my $action = _build_action(source => $source, dest => $dest, logger => $logger);

    $action->run;

    is $output, 'my scenario|rsync';
};

sub _build_action {
    my (%params) = @_;

    my $logger = $params{logger} || Test::MonkeyMock->new->mock(log => sub {});

    return App::rmachine::mirror->new(
        scenario => 'my scenario',
        command_runner => App::rmachine::command_runner->new,
        logger => $logger, %params
    );
}

done_testing;
