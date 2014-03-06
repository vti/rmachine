package App::rmachine::snapshot;

use strict;
use warnings;

use Cwd qw(realpath);
use App::rmachine::command::rsync;
use App::rmachine::mirror;
use App::rmachine::util qw(is_dir_empty current_time join_dirs join_dirs_and_file);

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{scenario} = $params{scenario};
    $self->{command_runner} = $params{command_runner};

    $self->{source} = $params{source};
    $self->{dest} = $params{dest};

    $self->{quiet} = $params{quiet};
    $self->{exclude} = $params{exclude};
    $self->{logger} = $params{logger};

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
        if (!is_dir_empty($self->{dest})) {
	    die "Error: link '$latest_link' does not exist, but '$self->{dest}' is not empty\n";
        }
	else {
	    my $mirror = $self->_build_mirror_action(
		command_runner => $self->{command_runner},
		source => $self->{source},
		dest => $new_snapshot_dest
	    );
	    $mirror->run;

            return $self->{command_runner}->run("ln -s '$new_snapshot_dest' '$latest_link'");
	}
    }

    my $changes = '';
    my $rsync_changes = App::rmachine::command::rsync->new(
        command_runner => $self->{command_runner},
        source => join_dirs($self->{source}),
        dest => join_dirs($latest_link),
        exclude => $self->{exclude},
        'dry-run' => 1,
    )->run(sub {
        $changes .= $_ if /rmachine:/;
    });

    if ($changes) {
        $self->log('changes', 'Found changes');

	my $latest_resolved = realpath("$latest_link");
        $self->{command_runner}->run("mkdir '$new_snapshot_dest'");
        $self->{command_runner}->run("cp -alR $latest_resolved/* $new_snapshot_dest");

        $self->log('rsync');
        App::rmachine::command::rsync->new(
            command_runner => $self->{command_runner},
            source => "$self->{source}/",
            dest => $new_snapshot_dest,
            exclude => $self->{exclude}
        )->run;

        $self->{command_runner}->run("rm $latest_link");
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
