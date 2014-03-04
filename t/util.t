use strict;
use warnings;

use Test::More;

use App::rmachine::util qw(build_excludes);

subtest 'return empty exlude' => sub {
	is '', build_excludes('');
};

subtest 'return exlude' => sub {
	is '--exclude=foo --exclude=bar --exclude=baz', build_excludes('foo,bar,baz');
};

done_testing;
