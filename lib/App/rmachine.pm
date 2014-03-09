package App::rmachine;

use strict;
use warnings;

our $VERSION = '0.01';

use Error::Tiny;
use Config::Tiny;
use App::rmachine::logger;
use App::rmachine::action_runner;
use App::rmachine::command_runner;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{config_file} = $params{config_file} || $self->_locate_config_file;
    $self->{log_file}    = $params{log_file}    || $self->_locate_log_file;
    $self->{quiet}       = $params{quiet};
    $self->{test}        = $params{test};
    $self->{force}       = $params{force};

    $self->{logger} = App::rmachine::logger->new(
        log_file => $self->{log_file},
        quiet    => $self->{quiet}
    );

    return $self;
}

sub run {
    my $self = shift;

    $self->{logger}->log('rmachine', 'start', 'Starting');

    my $config = $self->{config} = $self->_read_config;

    my @scenarios = sort grep { /^scenario:/ } keys %$config;
    $self->{logger}->log('rmachine', 'scenarios',
        'Found ' . scalar(@scenarios) . ' scenario(s)');

    my $action_runner = $self->_build_action_runner;

    my $any_errors = 0;
    foreach my $scenario (@scenarios) {
        my %params = (%{$config->{_} || {}}, %{$config->{$scenario} || {}});

        try {
            $action_runner->run($scenario, %params);
        }
        catch {
            $any_errors++;
        };
    }

    $self->{logger}->log('rmachine', 'end',
        'Finishing: ' . ($any_errors ? 'Some errors' : 'All successful'));
}

sub _read_config {
    my $self = shift;

    $self->{logger}
      ->log('rmachine', 'config', 'Reading ' . $self->{config_file});
    my $config = Config::Tiny->read($self->{config_file}, 'encoding(UTF-8)')
      || die "$Config::Tiny::errstr\n";

    my @scenarios = sort grep { /^scenario:/ } keys %$config;

    my @known_types = qw/mirror snapshot/;
    foreach my $scenario (@scenarios) {
        my %params = (%{$config->{_} || {}}, %{$config->{$scenario} || {}});

        if (!grep { $params{type} eq $_ } @known_types) {
            die "Error: Unknown type '$params{type}'\n";
        }
    }

    return $config;
}

sub _locate_config_file {
    my $self = shift;

    my @locations =
      ("$ENV{HOME}/.rmachine/rmachine.conf", "/etc/rmachine/rmachine.conf");
    return $self->_locate_file(\@locations, 'config');
}

sub _locate_log_file {
    my $self = shift;

    my @locations =
      ("$ENV{HOME}/.rmachine/rmachine.log", "/var/log/rmachine.log");
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

    return $action_class->new(%params);
}

sub _build_action_runner {
    my $self = shift;
    my (%params) = @_;

    my $command_runner = $self->_build_command_runner;

    return App::rmachine::action_runner->new(
        logger         => $self->{logger},
        force          => $self->{force},
        command_runner => $command_runner,
        start_time     => time,
        %params
    );
}

sub _build_command_runner {
    my $self = shift;
    my (%params) = @_;

    return App::rmachine::command_runner->new(
        quiet => $self->{quiet},
        test  => $self->{test},
        %params
    );
}

1;
