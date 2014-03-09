package App::rmachine::command::duplicity;

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

sub run {
    my $self = shift;
    my (%params) = @_;

    die 'duplicity requires env PASSPHRASE'
      unless $self->{env} && $self->{env} =~ m/PASSPHRASE/;

    return $self->SUPER::run(%params);
}

sub _build_command {
    my $self = shift;

    my $dry_run = $self->{'dry-run'} ? ' --dry-run' : '';
    my $excludes = $self->_build_excludes($self->{exclude});

    return
        'duplicity'
      . $excludes
      . $dry_run . ' '
      . $self->{source} . ' '
      . $self->{dest};
}

sub _build_excludes {
    my $self = shift;
    my ($excludes) = @_;

    return '' unless $excludes;

    return ' ' . join ' ', map { "--exclude $_" } split /,/, $excludes;
}

1;
