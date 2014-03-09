package App::rmachine::snapshot;

use strict;
use warnings;

use Cwd qw(realpath);
use App::rmachine::command::rsync;
use App::rmachine::mirror;
use App::rmachine::util
  qw(is_dir_empty current_time join_dirs join_dirs_and_file);

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{scenario}       = $params{scenario};
    $self->{command_runner} = $params{command_runner};

    $self->{env}    = $params{env};
    $self->{source} = $params{source};
    $self->{dest}   = $params{dest};

    $self->{quiet}   = $params{quiet};
    $self->{exclude} = $params{exclude};
    $self->{logger}  = $params{logger};

    return $self;
}

sub run {
    my $self = shift;

    my $latest_link = join_dirs_and_file $self->{dest}, 'latest';

    if (-e $latest_link && !-l $latest_link) {
        die "Error: link '$latest_link' is not a symlink\n";
    }

    my $new_snapshot = $self->_build_new_snapshot_name();
    my $new_snapshot_dest = join_dirs $self->{dest}, $new_snapshot;

    if (!-e $latest_link) {
        $self->log('latest', 'Did not find latest symlink');
        if (!is_dir_empty($self->{dest})) {
            die "Error: link '$latest_link' does not exist,"
              . " but '$self->{dest}' is not empty\n";
        }
        else {
            $self->log('mirror', 'Mirroring first snapshot');
            my $mirror = $self->_build_mirror_action(
                env            => $self->{env},
                scenario       => $self->{scenario},
                command_runner => $self->{command_runner},
                source         => $self->{source},
                dest           => $new_snapshot_dest
            );
            $mirror->run;

            $self->log('ln', 'Symlinking latest');
            $self->{command_runner}
              ->run("ln -s '$new_snapshot_dest' '$latest_link'");
            return;
        }
    }

    my $command = App::rmachine::command::rsync->new(
        env            => $self->{env},
        command_runner => $self->{command_runner},
        source         => join_dirs($self->{source}),
        dest           => join_dirs($latest_link),
        exclude        => $self->{exclude}
    );

    if ($command->has_source_changed) {
        $self->log('changes', 'Found changes');

        $self->log('mkdir', 'Making new snapshot directory');
        $self->{command_runner}->run("mkdir '$new_snapshot_dest'");

        $self->log('cp', 'Copying');
        $self->{command_runner}
          ->run("cp -alR $latest_link '$new_snapshot_dest'");

        $self->log('rsync');

        my $command = App::rmachine::command::rsync->new(
            env            => $self->{env},
            command_runner => $self->{command_runner},
            source         => join_dirs($self->{source}),
            dest           => join_dirs($new_snapshot_dest),
            exclude        => $self->{exclude}
        );
        $command->run;

        $self->log('rm', 'Removing latest link');
        $self->{command_runner}->run("rm $latest_link");

        $self->log('ln', 'Symlinking latest');
        $self->{command_runner}->run("ln -s $new_snapshot_dest $latest_link");
    }
    else {
        $self->log('changes', 'No changes');
    }

    return;
}

sub log {
    my $self = shift;

    $self->{logger}->log($self->{scenario}, @_);
}

sub _build_new_snapshot_name {
    my $self = shift;

    return current_time();
}

sub _build_mirror_action {
    my $self = shift;

    return App::rmachine::mirror->new(logger => $self->{logger}, @_);
}

1;
