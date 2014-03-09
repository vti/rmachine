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

    $self->{cmd} = 'rsync';

    $self->{encryption} = $params{encryption};
    $self->{password}   = $params{password};

    $self->{scenario}       = $params{scenario};
    $self->{command_runner} = $params{command_runner};
    $self->{logger}         = $params{logger};

    $self->{env}     = $params{env};
    $self->{source}  = $params{source};
    $self->{dest}    = $params{dest};
    $self->{exclude} = $params{exclude};

    if (my $encryption = $self->{encryption}) {
        if ($encryption eq 'gpg') {
            $self->{cmd} = 'duplicity';

            die "Password is required when using gpg encryption"
              unless $self->{password};
        }
        else {
            die "Ecnryption '$encryption' is not supported";
        }
    }

    return $self;
}

sub run {
    my $self = shift;

    $self->log('run', $self->{cmd});

    return $self->_build_command(
        $self->{cmd},
        source         => $self->{source},
        dest           => $self->{dest},
        exclude        => $self->{exclude},
        command_runner => $self->{command_runner},
    )->run;
}

sub log {
    my $self = shift;

    $self->{logger}->log($self->{scenario}, @_);
}

sub _build_command {
    my $self = shift;
    my ($command, %params) = @_;

    if ($command eq 'duplicity') {
        $params{env} = 'PASSPHRASE=' . $self->{password};
    }

    my $command_class = 'App::rmachine::command::' . $command;
    return $command_class->new(%params);
}

1;
