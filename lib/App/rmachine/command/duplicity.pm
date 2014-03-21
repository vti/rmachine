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

    $self->{type} = $params{type};
    $self->{'full-if-older-than'} = $params{'full-if-older-than'};
    $self->{exclude} = $params{exclude};

    return $self;
}

sub has_source_changed {
    my $self = shift;
    my (%params) = @_;

    my $changes = 0;
    my $command = $self->_build_command('dry-run' => 1);
    $self->{command_runner}->run(
        $command,
        env       => $self->{env},
        output_cb => sub {
            if (/DeltaEntries (\d+)/) {
                $changes = $1;
            }
        },
        %params
    );

    return $changes ? 1 : 0;
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

    my $full     = $self->{type} && $self->{type} eq 'mirror' ? ' full' : '';

    my $args = '';
    my $dry_run  = $self->{'dry-run'} ? ' --dry-run' : '';
    my $excludes = $self->_build_excludes($self->{exclude});
    if (my $arg = $self->{'full-if-older-than'}) {
        $args .= ' --full-if-older-than=' . $arg;
    }

    return
        'duplicity'
      . $full
      . $args
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
