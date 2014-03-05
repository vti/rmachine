package App::rmachine::logger;

use strict;
use warnings;

use Time::Piece;
use App::rmachine::util qw(current_time);

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{quiet} = $params{quiet};
    $self->{log_file} = $params{log_file};

    return $self;
}

sub log {
    my $self = shift;
    my ($message) = @_;

    my $log_message = join ' ', current_time(), $message;
    $log_message .= "\n";

    open my $fh, '>>:encoding(UTF-8)', $self->{log_file} or die "Can't open log file '$self->{log_file}': $!\n";
    print $fh $log_message;
    close $fh;

    print $log_message unless $self->{quiet};

    return $self;
}

1;
