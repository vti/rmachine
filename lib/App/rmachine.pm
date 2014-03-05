package App::rmachine;

use strict;
use warnings;

our $VERSION = '0.01';

use Config::Tiny;
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

    $self->{logger} = App::rmachine::logger->new(log_file => $self->{log_file}, quiet => $self->{quiet});


    return $self;
}

sub run {
    my $self = shift;

    $self->{logger}->log('rmachine', 'start', 'Starting');

    my $config = $self->{config} = $self->_read_config;

    my @scenarios = sort grep {/^scenario:/} keys %$config;
    $self->{logger}->log('rmachine', 'scenarios', 'Found ' . scalar(@scenarios) . ' scenario(s)');

    foreach my $scenario (@scenarios) {
        my %params = (%{$config->{_} || {}}, %{$config->{$scenario} || {}});

        $params{scenario} = $scenario;
        $params{type} ||= 'mirror';
        $params{logger} = $self->{logger};

        $self->{logger}->log($scenario, 'start');

        if ($params{type} eq 'mirror') {
            $self->_build_action('mirror', %params)->run;
        }
        elsif ($params{type} eq 'snapshot') {
            $self->_build_action('snapshot', %params)->run;
        }
        else {
            die "Unknown type '$params{type}'\n";
        }

        $self->{logger}->log($scenario, 'end');
    }

    $self->{logger}->log('rmachine', 'end', 'Finishing');
}

sub _read_config {
    my $self = shift;

    $self->{logger}->log('rmachine', 'config', 'Reading ' . $self->{config_file});
    return Config::Tiny->read($self->{config_file}, 'encoding(UTF-8)') || die "$Config::Tiny::errstr\n";
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
