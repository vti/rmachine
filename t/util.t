use strict;
use warnings;

use Test::More;

use App::rmachine::util qw(join_dirs join_dirs_and_file);

subtest 'join empty dirs' => sub {
    is join_dirs(), '';
};

subtest 'join one dir' => sub {
    is join_dirs('foo'), 'foo/';
};

subtest 'join dirs' => sub {
    is join_dirs('foo', 'bar'), 'foo/bar/';
};

subtest 'join dirs with slashes' => sub {
    is join_dirs('foo/', 'bar/'), 'foo/bar/';
};

subtest 'join dirs with front slashes' => sub {
    is join_dirs('/foo', '/bar'), '/foo/bar/';
};

subtest 'join dirs with mixed slashes' => sub {
    is join_dirs('/foo/', '/bar/'), '/foo/bar/';
};

subtest 'join dirs and file with mixed slashes' => sub {
    is join_dirs_and_file('/foo/', '/bar'), '/foo/bar';
};

done_testing;
