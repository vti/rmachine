package TestUtils;

use strict;
use warnings;

use File::Temp qw(tempdir tempfile);

sub prepare_file {
    my $class = shift;
    my ($content) = @_;

    my ($fh, $filename) = tempfile();
    print $fh $content if defined $content;
    close $fh;

    return $filename;
}

sub read_file {
    my $class = shift;
    my ($filename) = @_;

    open my $fh, '<', $filename;
    my $content = do { local $/; <$fh> };
    close $fh;

    return $content;
}

sub prepare_tree {
    my $class = shift;
    my %params = @_;

    my $dir = tempdir(CLEANUP => 1);

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
