use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;

use App::rmachine::mirror;

subtest 'create command with correct arguments' => sub {
    my $action = _build_action(source => 'foo', dest => 'bar', exclude => '123');

    $action->run;

    my %arguments = $action->mocked_call_args('_build_command');

    is_deeply \%arguments, {
        source => 'foo',
        dest => 'bar',
        exclude => '123',
        command_runner => undef
    };
};

sub _build_action {
    my (%params) = @_;

    my $logger = Test::MonkeyMock->new;
    $logger->mock(log => sub {});

    my $command = $params{command} || Test::MonkeyMock->new;
    $command->mock(run => sub {});

    my $action = App::rmachine::mirror->new(logger => $logger, %params);
    $action = Test::MonkeyMock->new($action);
    $action->mock(_build_command => sub { $command });

    return $action;
}

done_testing;
