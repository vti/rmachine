package App::rmachine::snapshot;

use strict;
use warnings;

use Cwd qw(realpath);
use App::rmachine::command::rsync;
use App::rmachine::mirror;
use App::rmachine::util qw(is_dir_empty current_time);

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

    my $latest_link = "$self->{dest}/latest";

    if (-e $latest_link && !-l $latest_link) {
        die "Error: link '$self->{dest}/latest' is not a symlink\n";
    }

    if (!-e $latest_link) {
        if (!is_dir_empty($self->{dest})) {
	    die "Error: link '$self->{dest}/latest' does not exist, but '$self->{dest}' is not empty\n";
        }
	else {
            my $new_snapshot = $self->_build_new_snapshot_name();

	    my $mirror = $self->_build_mirror_action(
		command_runner => $self->{command_runner},
		source => $self->{source},
		dest => "$self->{dest}/$new_snapshot/"
	    );
	    $mirror->run;

            return $self->{command_runner}->run("ln -s '$self->{dest}/$new_snapshot' '$self->{dest}/latest'");
	}
    }

    my $changes = '';
    my $rsync_changes = App::rmachine::command::rsync->new(
        command_runner => $self->{command_runner},
        source => "$self->{source}/",
        'dry-run' => 1,
        dest => "$self->{dest}/latest/",
        exclude => $self->{exclude}
    )->run(sub {
        $changes .= $_ if /rmachine:/;
    });

    if ($changes) {
        $self->log('changes', 'Found changes');

        my $new_snapshot = $self->_build_new_snapshot_name();

	my $latest_resolved = realpath("$self->{dest}/latest");
        $self->{command_runner}->run("mkdir '$self->{dest}/$new_snapshot'");
        $self->{command_runner}->run("cp -alR $latest_resolved/* $self->{dest}/$new_snapshot");

        $self->log('rsync');
        App::rmachine::command::rsync->new(
            command_runner => $self->{command_runner},
            source => "$self->{source}/",
            dest => "$self->{dest}/$new_snapshot/",
            exclude => $self->{exclude}
        )->run;

        $self->{command_runner}->run("rm $self->{dest}/latest");
        $self->{command_runner}->run("ln -s $self->{dest}/$new_snapshot $self->{dest}/latest");
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
