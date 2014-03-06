package App::rmachine::command_runner;

use strict;
use warnings;

use App::rmachine::exception::failed_exit;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{test} = $params{test};
    $self->{quiet} = $params{quiet};
    $self->{nice} = $params{nice};
    $self->{ionice} = $params{ionice};

    return $self;
}

sub run {
    my $self = shift;
    my ($command, $output_cb) = @_;

    $output_cb ||= sub {};

    if (my $ionice = $self->{ionice}) {
        $command = "ionice $ionice $command";
    }
    if (my $nice = $self->{nice}) {
        $command = "nice $nice $command";
    }

    print $command, "\n" unless $self->{quiet};

    return 0 if $self->{test};

    open my $fh, "$command |" or die "Can't fork\n";

    while (<$fh>) {
        $output_cb->($_);
        print unless $self->{quiet};
    }
    close $fh;

    App::rmachine::exception::failed_exit->throw("rv=$?") if $?;

    return $?;
}

1;
