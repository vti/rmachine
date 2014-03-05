package App::rmachine::util;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw(build_excludes is_dir_empty current_time);

use Time::Piece;
use Time::HiRes qw(gettimeofday);

sub build_excludes {
	my $excludes = shift;

	return '' unless $excludes;

	return join ' ', map { "--exclude=$_" } split /,/, $excludes;
}

sub is_dir_empty {
    my $dirname = shift;

    opendir(my $dh, $dirname) or die "Not a directory";
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
}

sub current_time {
    my $time = Time::Piece->new->strftime('%Y-%m-%dT%T');
    my (undef, $microseconds) = gettimeofday;
    $microseconds =~ s{(\d{4})\d+}{$1};

    return $time . '.' . $microseconds . Time::Piece->new->strftime('%z');
}

1;
