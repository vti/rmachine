package App::rmachine::mirror;

use strict;
use warnings;

use App::rmachine::command::rsync;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{scenario} = $params{scenario};
    $self->{command_runner} = $params{command_runner};
    $self->{logger} = $params{logger};

    $self->{source} = $params{source};
    $self->{dest} = $params{dest};
    $self->{exclude} = $params{exclude};

    return $self;
}

sub run {
    my $self = shift;

    $self->log('rsync');
    return $self->_build_command(
	source => $self->{source},
	dest => $self->{dest},
	exclude => $self->{exclude},
        command_runner => $self->{command_runner},
    )->run;
}

sub log {
    my $self = shift;

    $self->{logger}->log($self->{scenario}, @_);
}

sub _build_command {
    my $self = shift;

    return App::rmachine::command::rsync->new(@_);
}

1;
