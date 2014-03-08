use strict;
use warnings;

use Test::More;
use Test::Fatal;

use App::rmachine::command_runner;

subtest 'return zero on success' => sub {
    my $runner = _build_runner();

    is $runner->run('echo "hello"'), 0;
};

subtest 'throw on failure' => sub {
    my $runner = _build_runner();

    like exception { $runner->run('false') }, qr/rv=\d+/;
};

subtest 'call output_cb' => sub {
    my $runner = _build_runner();

    my $output = '';
    $runner->run(
        'echo "hi"',
        output_cb => sub {
            $output .= $_[0];
        }
    );

    is $output, "hi\n";
};

subtest 'set env' => sub {
    my $runner = _build_runner();

    my $output = '';
    $runner->run(
        'echo "$FOO,$BAZ"',
        env       => 'FOO=bar BAZ="baz"',
        output_cb => sub {
            $output .= $_[0];
        }
    );

    is $output, "bar,baz\n";
};

subtest 'cleanup env' => sub {
    my $runner = _build_runner();

    $ENV{FOO} = 'hi';

    my $output = '';
    $runner->run(
        'echo $FOO',
        env       => 'FOO=bar',
        output_cb => sub {
            $output .= $_[0];
        }
    );

    is $ENV{FOO}, 'hi';
};

sub _build_runner {
    my (%params) = @_;

    return App::rmachine::command_runner->new(%params);
}

done_testing;
