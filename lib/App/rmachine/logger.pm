package App::rmachine::logger;

use strict;
use warnings;

use Time::Piece;
use File::ReadBackwards;
use App::rmachine::util qw(current_time);

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{quiet}    = $params{quiet};
    $self->{log_file} = $params{log_file};

    return $self;
}

sub log {
    my $self = shift;
    my ($source, $action, $message) = @_;

    $message = '' unless defined $message;

    my $log_message = join ' ', current_time(), "[$source]", "[$action]",
      $message;
    $log_message .= "\n";

    open my $fh, '>>:encoding(UTF-8)', $self->{log_file}
      or die "Can't open log file '$self->{log_file}': $!\n";
    print $fh $log_message;
    close $fh;

    print $log_message unless $self->{quiet};

    return $self;
}

sub tail {
    my $self = shift;
    my ($n) = @_;

    $n = 1 unless defined $n;

    my $bw = File::ReadBackwards->new($self->{log_file})
      or die "Can't open log file '$self->{log_file}': $!\n";

    my @tail;

    while (defined(my $line = $bw->readline)) {
        push @tail, $line;

        last unless --$n;
    }

    return join "\n", reverse @tail;
}

sub grep_last {
    my $self = shift;
    my (%params) = @_;

    my $bw = File::ReadBackwards->new($self->{log_file})
      or die "Can't open log file '$self->{log_file}': $!\n";

    while (defined(my $log_line = $bw->readline)) {
        my ($date, $source, $action, $message) =
          $log_line =~ m/^([^ ]+) \[(.*?)\] \[(.*?)\] (.*)/;

        if (my $needed_source = $params{source}) {
            next unless $source eq $needed_source;
        }

        if (my $needed_action = $params{action}) {
            next unless $action eq $needed_action;
        }

        if (my $needed_message = $params{message}) {
            next unless $message =~ $needed_message;
        }

        return {
            date    => $date,
            source  => $source,
            action  => $action,
            message => $message
        };
    }

    return;
}

1;
