package App::rmachine;

use strict;
use warnings;

our $VERSION = '0.01';

use Error::Tiny;
use Config::Tiny;
use Time::Crontab;
use App::rmachine::mirror;
use App::rmachine::snapshot;
use App::rmachine::logger;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{config_file} = $params{config_file} || $self->_locate_config_file;
    $self->{log_file} = $params{log_file} || $self->_locate_log_file;
    $self->{quiet} = $params{quiet};
    $self->{test} = $params{test};
    $self->{force} = $params{force};

    $self->{logger} = App::rmachine::logger->new(log_file => $self->{log_file}, quiet => $self->{quiet});

    return $self;
}

sub run {
    my $self = shift;

    $self->{logger}->log('rmachine', 'start', 'Starting');

    my $config = $self->{config} = $self->_read_config;

    my @scenarios = sort grep {/^scenario:/} keys %$config;
    $self->{logger}->log('rmachine', 'scenarios', 'Found ' . scalar(@scenarios) . ' scenario(s)');

    my $start_time = time;

    foreach my $scenario (@scenarios) {
        my %params = (%{$config->{_} || {}}, %{$config->{$scenario} || {}});

        $params{scenario} = $scenario;
        $params{type} ||= 'mirror';
        $params{logger} = $self->{logger};

        if (!$self->{force} && !Time::Crontab->new($params{period})->match($start_time)) {
            $self->{logger}->log($scenario, 'skip', 'Does not match period');
            next;
        }

        $self->{logger}->log($scenario, 'start');

        try {
            $self->_build_action($params{type}, %params)->run;
        
            $self->{logger}->log($scenario, 'end', 'Success');
        } catch {
            $self->{logger}->log($scenario, 'end', 'Failure');
        };

        $self->{logger}->log($scenario, 'end');
    }

    $self->{logger}->log('rmachine', 'end', 'Finishing');
}

sub _read_config {
    my $self = shift;

    $self->{logger}->log('rmachine', 'config', 'Reading ' . $self->{config_file});
    my $config = Config::Tiny->read($self->{config_file}, 'encoding(UTF-8)') || die "$Config::Tiny::errstr\n";

    my @scenarios = sort grep {/^scenario:/} keys %$config;

    my @known_types = qw/mirror snapshot/;
    foreach my $scenario (@scenarios) {
        my %params = (%{$config->{_} || {}}, %{$config->{$scenario} || {}});

        try {
	    Time::Crontab->new($params{period});
        } catch {
            my $e = shift;
            die "Error: Wrong period '$params{period}'\n";
        };

        if (!grep { $params{type} eq $_ } @known_types) {
            die "Error: Unknown type '$params{type}'\n";
        }
    }

    return $config;
}

sub _locate_config_file {
    my $self = shift;

    my @locations = ("$ENV{HOME}/.rmachine/rmachine.conf", "/etc/rmachine/rmachine.conf");
    return $self->_locate_file(\@locations, 'config');
}

sub _locate_log_file {
    my $self = shift;

    my @locations = ("$ENV{HOME}/.rmachine/rmachine.log", "/var/log/rmachine.log");
    return $self->_locate_file(\@locations, 'log');
}

sub _locate_file {
    my $self = shift;
    my ($locations, $type) = @_;

    foreach my $location (@$locations) {
        return $location if -f $location;
    }

    die "Can't locate $type file in @$locations\n";
}

sub _build_action {
    my $self = shift;
    my ($action_name, %params) = @_;

    my $action_class = 'App::rmachine::' . $action_name;

    return $action_class->new(%params, command_runner => $self->_build_command_runner);
}

sub _build_command_runner {
    my $self = shift;

    return App::rmachine::command_runner->new(quiet => $self->{quiet}, test => $self->{test});
}

1;
