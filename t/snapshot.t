use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::MonkeyMock;

use lib 't/lib';

use App::rmachine::snapshot;
use App::rmachine::command_runner;
use TestUtils;

subtest 'throw when latest link is not a link' => sub {
    my $tree = TestUtils->prepare_tree(latest => '123');

    my $action = _build_action(dest => $tree);

    like exception { $action->run }, qr/Error: link '.*?' is not a symlink/;
};

subtest 'throw when latest does not exist but dest directory is not empty' => sub {
    my $tree = TestUtils->prepare_tree(foo => '123');

    my $action = _build_action(dest => $tree);

    like exception { $action->run }, qr/Error: link '.*?' does not exist, but '.*?' is not empty/;
};

subtest 'run mirror when not latest link' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar');
    my $dest = TestUtils->prepare_tree();

    my $action = _build_action(source => $source, dest => $dest);
    $action->run;

    my $result = TestUtils->read_tree($dest);

    ok -l "$dest/latest";
    is_deeply $result->{latest}, {foo => 1};

    my ($date) = sort keys %$result;
    like $date, qr/\d+-\d+-\d+T\d+:\d+:\d/;
    is_deeply $result->{$date}, {foo => 1};
};

subtest 'create new snapshot' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar');
    my $dest = TestUtils->prepare_tree();

    my $action = _build_action(source => $source, dest => $dest);
    $action->run;

    open my $fh, '>', "$source/new_file";
    print $fh 'hello';
    close $fh;

    $action = _build_action(source => $source, dest => $dest);
    $action->run;

    my $result = TestUtils->read_tree($dest);

    ok -l "$dest/latest";
    is_deeply $result->{latest}, {foo => 1, new_file => 1};

    my ($date1, $date2) = sort keys %$result;
    like $date1, qr/\d+-\d+-\d+T\d+:\d+:\d/;
    is_deeply $result->{$date1}, {foo => 1};

    like $date2, qr/\d+-\d+-\d+T\d+:\d+:\d/;
    is_deeply $result->{$date2}, {foo => 1, new_file => 1};
};

subtest 'not create new snapshot when nothing changed' => sub {
    my $source = TestUtils->prepare_tree(foo => 'bar');
    my $dest = TestUtils->prepare_tree();

    my $action = _build_action(source => $source, dest => $dest);
    $action->run;

    $action = _build_action(source => $source, dest => $dest);
    $action->run;

    my $result = TestUtils->read_tree($dest);

    ok -l "$dest/latest";
    is_deeply $result->{latest}, {foo => 1};

    my @dates = sort keys %$result;
    is scalar(@dates), 2;
};

sub _build_action {
    my (%params) = @_;

    my $logger = Test::MonkeyMock->new;
    $logger->mock(log => sub {});

    return App::rmachine::snapshot->new(command_runner => App::rmachine::command_runner->new, logger => $logger, %params);
}

done_testing;
