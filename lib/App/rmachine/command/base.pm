package App::rmachine::command::base;

use strict;
use warnings;

require Carp;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{env}            = $params{env};
    $self->{command_runner} = $params{command_runner};

    Carp::croak('command_runner is required') unless $self->{command_runner};

    return $self;
}

sub run {
    my $self = shift;
    my (%params) = @_;

    my $command = $self->_build_command;
    return $self->{command_runner}->run($command, env => $self->{env}, %params);
}

sub _build_command {
    my $self = shift;

    ...;
}

1;
