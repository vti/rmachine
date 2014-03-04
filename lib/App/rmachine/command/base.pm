package App::rmachine::command::base;

use strict;
use warnings;

require Carp;
use App::rmachine::command_runner;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{command_runner} = $params{command_runner};

    Carp::croak('command_runner is required') unless $self->{command_runner};

    return $self;
}

sub run {
    my $self = shift;
    my ($output_cb) = @_;

    my $command = $self->_build_command;
    return $self->{command_runner}->run($command, $output_cb);
}

sub _build_command {
    my $self = shift;

    ...
}

1;
