package App::rmachine::command::rsync;

use strict;
use warnings;

use base 'App::rmachine::command::base';

require Carp;

sub new {
    my $self = shift->SUPER::new(@_);
    my (%params) = @_;

    $self->{source} = $params{source} || Carp::croak('source required');
    $self->{dest}   = $params{dest}   || Carp::croak('dest required');

    $self->{'dry-run'} = $params{'dry-run'};
    $self->{exclude} = $params{exclude};

    return $self;
}

sub has_source_changed {
    my $self = shift;
    my (%params) = @_;

    my $changes = '';
    my $command = $self->_build_command('dry-run' => 1);
    $self->{command_runner}->run(
        $command,
        env       => $self->{env},
        output_cb => sub {
            $changes .= $_ if /rmachine:/;
        },
        %params
    );

    return $changes ? 1 : 0;
}

sub _build_command {
    my $self = shift;
    my (%params) = @_;

    my $dry_run = $params{'dry-run'} ? ' --dry-run' : '';
    my $excludes = $self->_build_excludes($self->{exclude});

    return
'rsync -rtDH --links --no-p --no-g --no-o --delete --delete-excluded -i --out-format="rmachine: %i %n%L" --chmod=Du+wx '
      . $excludes
      . $dry_run . ' '
      . "'$self->{source}'" . ' '
      . "'$self->{dest}'";
}

sub _build_excludes {
    my $self = shift;
    my ($excludes) = @_;

    return '' unless $excludes;

    return join ' ', map { "--exclude=$_" } split /,/, $excludes;
}

1;
