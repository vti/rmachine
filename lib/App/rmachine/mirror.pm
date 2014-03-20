package App::rmachine::mirror;

use strict;
use warnings;

use App::rmachine::command::rsync;
use App::rmachine::command::duplicity;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{backend} = $params{backend} || 'rsync';

    $self->{scenario}       = $params{scenario};
    $self->{command_runner} = $params{command_runner};
    $self->{logger}         = $params{logger};

    $self->{env}     = $params{env};
    $self->{source}  = $params{source};
    $self->{dest}    = $params{dest};
    $self->{exclude} = $params{exclude};

    return $self;
}

sub run {
    my $self = shift;

    $self->log('run', $self->{backend});

    my $command = $self->_build_command(
        $self->{backend},
        type           => 'mirror',
        env            => $self->{env},
        source         => $self->{source},
        dest           => $self->{dest},
        exclude        => $self->{exclude},
        command_runner => $self->{command_runner},
    );

    if ($command->has_source_changed) {
        $self->log('changes', 'Changes detected');

        $command->run;
    }
    else {
        $self->log('changes', 'No changes detected. Skip');
    }

    return $self;
}

sub log {
    my $self = shift;

    $self->{logger}->log($self->{scenario}, @_);
}

sub _build_command {
    my $self = shift;
    my ($command, %params) = @_;

    my $command_class = 'App::rmachine::command::' . $command;
    return $command_class->new(%params);
}

1;
