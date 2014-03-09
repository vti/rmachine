use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::MonkeyMock;

use App::rmachine::command::duplicity;

subtest 'run command with correct arguments' => sub {
    my $command_runner = Test::MonkeyMock->new;
    my $command        = _build_command(
        command_runner => $command_runner,
        source         => '/foo/bar',
        dest           => '/foo/baz'
    );

    my $cb = sub { };
    $command->run(output_cb => $cb);

    my ($got_cmd, %params) = $command_runner->mocked_call_args('run');

    is $got_cmd, 'duplicity /foo/bar /foo/baz';
    is $params{output_cb}, $cb;
};

subtest 'run command with dry-run' => sub {
    my $command_runner = Test::MonkeyMock->new;
    my $command        = _build_command(
        command_runner => $command_runner,
        source         => '/foo/bar',
        dest           => '/foo/baz',
        'dry-run'      => 1
    );

    $command->run;

    my ($got_cmd) = $command_runner->mocked_call_args('run');

    like $got_cmd, qr/ --dry-run /;
};

subtest 'throw when running without passphrase' => sub {
    my $command_runner = Test::MonkeyMock->new;
    my $command        = _build_command(
        command_runner => $command_runner,
        source         => '/foo/bar',
        dest           => '/foo/baz',
        env            => ''
    );

    like exception { $command->run }, qr/duplicity requires env PASSPHRASE/;
};

sub _build_command {
    my (%params) = @_;

    my $command_runner = $params{command_runner} || Test::MonkeyMock->new;
    $command_runner->mock(run => sub { });

    return App::rmachine::command::duplicity->new(
        env            => 'PASSPHRASE=bar',
        command_runner => $command_runner,
        %params
    );
}

done_testing;
