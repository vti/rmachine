use strict;
use warnings;

use Test::More;
use Test::MonkeyMock;
use Test::Fatal;
use Test::MockTime qw(set_absolute_time restore_time);

use lib 't/lib';

use TestUtils;

use Time::Piece;
use App::rmachine::logger;
use App::rmachine::action_runner;

subtest 'run immediately when never run' => sub {
    my $action = _mock_action();
    my $logger = _prepare_logger(new => 1);

    my $runner = _build_runner(logger => $logger, action => $action);
    $runner->run('scenario', period => '*/1 * * * *');

    ok $action->mocked_called('run');
    like $logger->tail(3), qr/No last run found, running immediately/;
};

subtest 'run immediately when wrong period but last run was long ago' => sub {
    my $action = _mock_action();

    set_absolute_time(0);
    my $logger = _prepare_logger();
    restore_time();

    my $runner = _build_runner(
        logger => $logger,
        action => $action,
        start_time =>
          localtime->strptime('2014-01-01 19:55:01', '%Y-%m-%d %T')->epoch
    );
    $runner->run('scenario', period => '*/9 * * * *');

    ok $action->mocked_called('run');
    like $logger->tail(3), qr/Running according to schedule/;
};

subtest 'run immediately when no period' => sub {
    my $action = _mock_action();
    my $logger = _prepare_logger();

    my $runner = _build_runner(logger => $logger, action => $action);
    $runner->run('scenario');

    ok $action->mocked_called('run');
    like $logger->tail(3), qr/No period found, running immediately/;
};

subtest 'not run when incorrect period' => sub {
    my $action = _mock_action();
    my $logger = _prepare_logger();

    my $runner = _build_runner(
        logger     => $logger,
        action     => $action,
        start_time => Time::Piece->new->strptime('19:55:01', '%T')->epoch
    );
    $runner->run('scenario', period => '*/10 * * * *');

    ok !$action->mocked_called('run');
    like $logger->tail(3), qr/Does not match period/;
};

subtest 'run when correct period' => sub {
    my $action = _mock_action();

    set_absolute_time(
        localtime->strptime('2014-01-01 19:45:00', '%Y-%m-%d %T')->epoch);
    my $logger = _prepare_logger();
    restore_time();

    my $runner = _build_runner(
        logger => $logger,
        action => $action,
        start_time =>
          localtime->strptime('2014-01-01 19:55:01', '%Y-%m-%d %T')->epoch
    );
    $runner->run('scenario', period => '*/5 * * * *');

    ok $action->mocked_called('run');
    like $logger->tail(3), qr/Running according to schedule/;
};

subtest 'run when correct period and ignore other scenarios' => sub {
    my $action = _mock_action();

    set_absolute_time(
        localtime->strptime('2014-01-01 19:55:01', '%Y-%m-%d %T')->epoch);
    my $logger = _prepare_logger(scenario => 'another scenario');
    restore_time();

    my $runner = _build_runner(
        logger => $logger,
        action => $action,
        start_time =>
          localtime->strptime('2014-01-01 19:55:01', '%Y-%m-%d %T')->epoch
    );
    $runner->run('scenario', period => '*/5 * * * *');

    ok $action->mocked_called('run');
    like $logger->tail(3), qr/No last run found/;
};

subtest 'run immediately when force' => sub {
    my $action = _mock_action();
    my $logger = _prepare_logger();

    my $runner =
      _build_runner(force => 1, logger => $logger, action => $action);
    $runner->run('scenario');

    ok $action->mocked_called('run');
    like $logger->tail(3), qr/Force mode, running immediately/;
};

subtest 'log action run' => sub {
    my $action = _mock_action();
    my $logger = _prepare_logger();

    my $runner =
      _build_runner(force => 1, logger => $logger, action => $action);
    $runner->run('scenario');

    ok $action->mocked_called('run');
    like $logger->tail(3), qr/\Q[scenario] [start]\E/;
    like $logger->tail(3), qr/\Qscenario] [end] Success\E/;
};

subtest 'log failed action run' => sub {
    my $action = _mock_action(run => sub { die 'here' });
    my $logger = _prepare_logger();

    my $runner =
      _build_runner(force => 1, logger => $logger, action => $action);
    like exception { $runner->run('scenario') }, qr/here/;

    ok $action->mocked_called('run');
    like $logger->tail(3), qr/\Q[scenario] [start]\E/;
    like $logger->tail(3), qr/\Q[scenario] [end] Failure: here\E/;
};

subtest 'run hook-before' => sub {
    my $action         = _mock_action();
    my $logger         = _prepare_logger();
    my $command_runner = _mock_command_runner();

    my $runner = _build_runner(
        logger         => $logger,
        action         => $action,
        command_runner => $command_runner
    );
    $runner->run('scenario', 'hook-before' => 'command');

    ok $action->mocked_called('run');
    like $logger->tail(5), qr/Running hook-before/;
    like $logger->tail(5), qr/\Q[hook-before] Started\E/;
    like $logger->tail(5), qr/\Q[hook-before] Finished\E/;
};

subtest 'abort when hook-before fails' => sub {
    my $action         = _mock_action();
    my $logger         = _prepare_logger();
    my $command_runner = _mock_command_runner(run => sub { die 'error' });

    my $runner = _build_runner(
        logger         => $logger,
        action         => $action,
        command_runner => $command_runner
    );
    $runner->run('scenario', 'hook-before' => 'command');

    ok !$action->mocked_called('run');
    like $logger->tail(5), qr/Running hook-before/;
    like $logger->tail(5), qr/\Q[hook-before] Started\E/;
    like $logger->tail(5), qr/\Q[hook-before] Failed\E/;
    like $logger->tail(5), qr/Skip because of failed hook/;
};

subtest 'run hook-after' => sub {
    my $action         = _mock_action();
    my $logger         = _prepare_logger();
    my $command_runner = _mock_command_runner();

    my $runner = _build_runner(
        logger         => $logger,
        action         => $action,
        command_runner => $command_runner
    );
    $runner->run('scenario', 'hook-after' => 'command');

    ok $action->mocked_called('run');
    like $logger->tail(5), qr/Running hook-after/;
    like $logger->tail(5), qr/\Q[hook-after] Started\E/;
    like $logger->tail(5), qr/\Q[hook-after] Finished\E/;
};

subtest 'ignore when hook-after fails' => sub {
    my $action         = _mock_action();
    my $logger         = _prepare_logger();
    my $command_runner = _mock_command_runner(run => sub { die 'error' });

    my $runner = _build_runner(
        logger         => $logger,
        action         => $action,
        command_runner => $command_runner
    );
    $runner->run('scenario', 'hook-after' => 'command');

    like $logger->tail(5), qr/Running hook-after/;
    like $logger->tail(5), qr/\Q[hook-after] Started\E/;
    like $logger->tail(5), qr/\Q[hook-after] Failed\E/;
};

sub _mock_action {
    my (%params) = @_;

    my $action = Test::MonkeyMock->new;
    $action->mock(run => $params{run} || sub { });
    return $action;
}

sub _mock_command_runner {
    my (%params) = @_;

    my $command_runner = Test::MonkeyMock->new;
    $command_runner->mock(run => $params{run} || sub { });
    return $command_runner;
}

sub _prepare_logger {
    my (%params) = @_;

    my $file = TestUtils->prepare_file;

    my $logger = App::rmachine::logger->new(log_file => $file);

    unless ($params{new}) {
        $logger->log($params{scenario} || 'scenario', 'end', 'Success');
    }

    return $logger;
}

sub _build_runner {
    my (%params) = @_;

    my $runner = App::rmachine::action_runner->new(%params);
    $runner = Test::MonkeyMock->new($runner);
    $runner->mock(_build_action => sub { $params{action} });
    return $runner;
}

done_testing;
