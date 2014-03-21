package App::rmachine::action_runner;

use strict;
use warnings;

use Error::Tiny;
use Time::Piece;
use Algorithm::Cron;
use App::rmachine::mirror;
use App::rmachine::snapshot;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{start_time}     = $params{start_time} || time;
    $self->{logger}         = $params{logger};
    $self->{force}          = $params{force};
    $self->{command_runner} = $params{command_runner};

    return $self;
}

sub run {
    my $self = shift;
    my ($scenario, %params) = @_;

    my $start_time = $self->{start_time};

    my $last_run = $self->_find_last_run($scenario);

    if ($self->{force}) {
        $self->log($scenario, 'run', 'Force mode, running immediately');
    }
    elsif (!$params{period}) {
        $self->log($scenario, 'run', 'No period found, running immediately');
    }
    elsif ($params{period}) {
        if (!$last_run) {
            $self->log($scenario, 'run',
                'No last run found, running immediately');
        }
        else {
            my $cron = Algorithm::Cron->new(
                base    => 'local',
                crontab => $params{period}
            );
            my $next_time = $cron->next_time($last_run);

            if ($next_time > $start_time) {
                $self->log($scenario, 'skip',
                    "Does not match period '$params{period}'");
                return;
            }

            $self->log($scenario, 'run',
                "Running according to schedule '$params{period}'");
        }
    }

    return if $self->_skip_because_of_hook_before($scenario, %params);

    $self->{logger}->log($scenario, 'start');

    try {
        $self->_build_action($params{type}, scenario => $scenario, %params)
          ->run;

        $self->{logger}->log($scenario, 'end', 'Success');
    }
    catch {
        my $e = shift;

        $self->{logger}->log($scenario, 'end', "Failure: " . $e->message);

        $e->throw;
    };

    $self->_run_hook_after($scenario, %params);

    return $self;
}

sub log {
    my $self = shift;

    return $self->{logger}->log(@_);
}

sub _skip_because_of_hook_before {
    my $self = shift;
    my ($scenario, %params) = @_;

    if (my $hook = $params{'hook-before'}) {
        $self->{logger}->log($scenario, 'hook-before', 'Running hook-before');

        my $command_runner = $self->{command_runner};

        my $skip;
        try {
            $self->{logger}->log($scenario, 'hook-before', 'Started');

            $command_runner->run($hook);

            $self->{logger}->log($scenario, 'hook-before', 'Finished');
        }
        catch {
            $self->{logger}->log($scenario, 'hook-before', 'Failed');

            $skip++;
        };

        if ($skip) {
            $self->{logger}
              ->log($scenario, 'run', 'Skip because of failed hook');
            return 1;
        }
    }

    return 0;
}

sub _run_hook_after {
    my $self = shift;
    my ($scenario, %params) = @_;

    if (my $hook = $params{'hook-after'}) {
        $self->{logger}->log($scenario, 'hook-after', 'Running hook-after');

        my $command_runner = $self->{command_runner};

        try {
            $self->{logger}->log($scenario, 'hook-after', 'Started');

            $command_runner->run($hook);

            $self->{logger}->log($scenario, 'hook-after', 'Finished');
        }
        catch {
            $self->{logger}->log($scenario, 'hook-after', 'Failed');
        };
    }
}

sub _find_last_run {
    my $self = shift;
    my ($scenario) = @_;

    my $last_run = $self->{logger}->grep_last(
        source  => $scenario,
        action  => 'end',
        message => qr/Success/
    );

    if ($last_run) {
        my $date = $last_run->{date};
        $date =~ s{\.\d+}{};    # remove milliseconds
        return gmtime->strptime($date, '%Y-%m-%dT%T%z')->epoch;
    }

    return;
}

sub _build_action {
    my $self = shift;
    my ($action_name, %params) = @_;

    my $action_class = 'App::rmachine::' . $action_name;

    return $action_class->new(
        logger         => $self->{logger},
        command_runner => $self->{command_runner},
        %params
    );
}

1;
