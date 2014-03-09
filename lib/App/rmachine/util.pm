package App::rmachine::util;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK =
  qw(is_dir_empty current_time join_dirs join_dirs_and_file);

use Time::Piece;
use Time::HiRes qw(gettimeofday);

sub is_dir_empty {
    my $dirname = shift;

    opendir(my $dh, $dirname) or die "Not a directory '$dirname'\n";
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
}

sub current_time {
    my $time = Time::Piece->new->strftime('%Y-%m-%dT%T');
    my (undef, $microseconds) = gettimeofday;
    $microseconds =~ s{(\d{4})\d+}{$1};

    return $time . '.' . $microseconds . Time::Piece->new->strftime('%z');
}

sub join_dirs_and_file {
    my (@dirs) = @_;

    return '' unless @dirs;

    my $front = shift @dirs;
    $front =~ s/\/$//;
    @dirs = map { s/^\///; s/\/$//; $_ } @dirs;
    join '/', $front, @dirs;
}

sub join_dirs {
    return '' unless @_;

    join_dirs_and_file(@_) . '/';
}

1;
