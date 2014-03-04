package App::rmachine::command::rsync;

use strict;
use warnings;

use base 'App::rmachine::command::base';

require Carp;
use App::rmachine::util qw(build_excludes);

sub new {
    my $self = shift->SUPER::new(@_);
    my (%params) = @_;

    $self->{source} = $params{source} || Carp::croak('source required');
    $self->{dest} = $params{dest} || Carp::croak('dest required');

    $self->{'dry-run'} = $params{'dry-run'};
    $self->{exclude} = $params{exclude};

    return $self;
}

sub _build_command {
    my $self = shift;

    my $dry_run = $self->{'dry-run'} ? ' --dry-run' : '';
    my $excludes = build_excludes($self->{exclude});

    return 'rsync -rtDH --links --no-p --no-g --no-o --delete --delete-excluded -i --out-format="rmachine: %i %n%L" --chmod=Du+wx ' . $excludes . $dry_run . ' ' . $self->{source} . ' ' . $self->{dest};
}

1;
