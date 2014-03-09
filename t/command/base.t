use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;

use App::rmachine::command::base;

subtest 'run command with correct arguments' => sub {
    my $command_runner = Test::MonkeyMock->new;
    $command_runner->mock(run => sub { });

    my $command = _build_command(command_runner => $command_runner);

    my $cb = sub { };
    $command->run(output_cb => $cb);

    my ($got_cmd, %params) = $command_runner->mocked_call_args('run');

    is $got_cmd, 'my command';
    is $params{output_cb}, $cb;
};

sub _build_command {
    my (%params) = @_;

    my $command_runner = $params{command_runner} || Test::MonkeyMock->new;

    return App::rmachine::command::test->new(command_runner => $command_runner);
}

done_testing;

package App::rmachine::command::test;
use base 'App::rmachine::command::base';

sub _build_command { 'my command' }
