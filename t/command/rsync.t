use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;

use App::rmachine::command::rsync;

subtest 'run command with correct arguments' => sub {
    my $command_runner = Test::MonkeyMock->new;
    my $command = _build_command(command_runner => $command_runner, source => '/foo/bar', dest => '/foo/baz');

    my $cb = sub {};
    $command->run($cb);

    my ($got_cmd, $got_cb) = $command_runner->mocked_call_args('run');

    is $got_cmd, 'rsync -rtDH --links --no-p --no-g --no-o --delete --delete-excluded -i --out-format="rmachine: %i %n%L" --chmod=Du+wx  /foo/bar /foo/baz';
    is $got_cb, $cb;
};

subtest 'run command with dry-run' => sub {
    my $command_runner = Test::MonkeyMock->new;
    my $command = _build_command(command_runner => $command_runner, source => '/foo/bar', dest => '/foo/baz', 'dry-run' => 1);

    $command->run;

    my ($got_cmd) = $command_runner->mocked_call_args('run');

    like $got_cmd, qr/ --dry-run /;
};

sub _build_command {
    my (%params) = @_;

    my $command_runner = $params{command_runner} || Test::MonkeyMock->new;
    $command_runner->mock(run => sub {});

    return App::rmachine::command::rsync->new(command_runner => $command_runner, %params);
}

done_testing;
