package TestUtils;

use strict;
use warnings;

use File::Temp qw(tempdir);

sub prepare_tree {
    my $class = shift;
    my %params = @_;

    my $dir = tempdir(CLEANUP => 0);

    foreach my $file (keys %params) {
        open my $fh, '>', "$dir/$file";
        print $fh $params{$file};
        close $fh;
    }

    return "$dir/";
}

sub read_tree {
    my $class = shift;
    my $dirname = shift;

    my $tree = {};
    opendir(my $dh, $dirname) or die "Not a directory";
    my @files = grep { $_ ne "." && $_ ne ".." } readdir($dh);
    closedir($dh);

    foreach my $file (@files) {
        if (-f "$dirname/$file") {
            $tree->{$file}++;
        }
        elsif (-d "$dirname/$file") {
            $tree->{$file} = $class->read_tree("$dirname/$file");
        }
    }

    return $tree;
}

1;
