use strict;
use warnings;

use Test::More;

use lib 't/lib';

use App::rmachine::logger;
use TestUtils;

subtest 'print to file' => sub {
    my $file = TestUtils->prepare_file;
    my $logger = _build_logger(log_file => $file);

    $logger->log('source', 'action', 'My message');

    like(TestUtils->read_file($file), qr/\[source\] \[action\] My message/);
};

subtest 'grep last by source' => sub {
    my $file = TestUtils->prepare_file("DATE [source] [action] Hi there\nDATE [source2] [action2] Hi here");
    my $logger = _build_logger(log_file => $file);

    my $line = $logger->grep_last(source => 'source');

    like $line->{message}, qr/Hi there/;
};

subtest 'grep last by action' => sub {
    my $file = TestUtils->prepare_file("DATE [source] [action] Hi there\nDATE [source2] [action2] Hi here");
    my $logger = _build_logger(log_file => $file);

    my $line = $logger->grep_last(action => 'action2');

    like $line->{message}, qr/Hi here/;
};

subtest 'return undef when nothing found' => sub {
    my $file = TestUtils->prepare_file("DATE [source] [action] Hi there\nDATE [source2] [action2] Hi here");
    my $logger = _build_logger(log_file => $file);

    my $line = $logger->grep_last(source => 'unknown');

    ok !defined $line;
};

sub _build_logger {
     App::rmachine::logger->new(@_);
}

done_testing;
