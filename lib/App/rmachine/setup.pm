package App::rmachine::setup;

use strict;
use warnings;

use FindBin ();
use Cwd ();
use App::rmachine::logger;

my $START_OF_CRONTAB = "# rmachine START";
my $END_OF_CRONTAB   = "# rmachine END";

sub new {
    my $class = shift;
    my (%opts) = @_;

    my $self = {};
    bless $self, $class;

    $self->{log_file}    = $opts{'--log'};
    $self->{config_file} = $opts{'--config'};
    $self->{quiet}       = $opts{'--quiet'};
    $self->{test}        = $opts{'--test'};
    $self->{force}       = $opts{'--force'};

    $self->{logger} = App::rmachine::logger->new(
        log_file => $self->{log_file},
        quiet    => $self->{quiet}
    );

    return $self;
}

sub run {
    my $self = shift;

    my $cron = $self->_slurp_current_cron;

    if ($cron =~ m/$START_OF_CRONTAB\s*.*?$END_OF_CRONTAB/sm) {
        $self->{logger}->log('rmachine', 'setup', 'Previous rmachine cron entry found');

        if ($self->{force}) {
            $self->{logger}->log('rmachine', 'setup', 'Reinstalling cron entry');

            my $new_cron = $self->_prepare_cron_entry;
            $cron =~ s/$START_OF_CRONTAB\s*.*?$END_OF_CRONTAB\n/$new_cron/sm;

            $self->_install_new_cron($cron);
        }
    }
    else {
        $self->{logger}->log('rmachine', 'setup', 'Previous rmachine cron entry not found');

        $self->{logger}->log('rmachine', 'setup', 'Installing new cron entry');

        $cron .= $self->_prepare_cron_entry;

        $self->_install_new_cron($cron);
    }

    return $self;
}

sub _prepare_cron_entry {
    my $self = shift;

    my $path_to_bin = $self->_detect_path_to_bin;

    my $options = '';
    if ($self->{log_file}) {
        $options .= ' --log ' . Cwd::abs_path($self->{log_file});
    }
    if ($self->{config_file}) {
        $options .= ' --config ' . Cwd::abs_path($self->{config_file});
    }

    return <<"EOC";
$START_OF_CRONTAB
*/5 * * * * perl $path_to_bin$options backup --quiet
$END_OF_CRONTAB
EOC
}

sub _slurp_current_cron {
    my $self = shift;

    return qx(crontab -l);
}

sub _install_new_cron {
    my $self = shift;
    my ($content) = @_;

    $self->{logger}->log('rmachine', 'setup', 'Saving changes to cron');

    open my $fh, "| crontab -" or die "Can't open crontab: $!";
    print $fh $content;
    close $fh;
}

sub _detect_path_to_bin {
    my $self = shift;

    return "$FindBin::RealBin/rmachine";
}

1;
