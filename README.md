# rmachine

WARNING: This is a complete documentation of the incomplete script, so the docs
decsribe more than is implemented for now! The work is still in progress.

rmachine is a simple, yet extensible backup tool, that uses rsync (or duplicity
in case of encryption) and harlinks underneath. It supports two types of
backups: mirrors and snapshots. Mirrors are just exact copies of your
directories, whether snapshots are incremented backups.

Here is a typical scenario of my laptop backup:

1. Check every 5 minutes if something changed in Documents/.
2. If something changed do a snaphot, otherwise do nothing.
3. Every 30 minutes do a full mirror backup of the snapshots to a ssh server,
   but only if I am connected to my home Wi-Fi network.

## More on snapshots

A bit more information on how snapshots are made.

1. run `rsync` in `--dry-run` to check for the changes
2. If changes were detected, `cp -laR` latest directory to a new snapshot directory
3. rsync old snapshot with the current backup directory
4. move `latest` symlink to a new snapshot

Here is a typical snapshots tree structure:

    /home/vti/.snapshots/
    ├── 2014-03-05T23:33:01.4750+0200
    │   ├── Doc 1.odt
    └── latest -> /home/vti/.snapshots/2014-03-05T23:33:01.4750+0200

## Configuring

Here is a configuration for the example shown above:

    nice = -n 19
    ionice = -c2 -n7

    [scenario:full_sync]
    type = mirror
    period = */30 * * * *
    source = /home/vti/.snapshots/
    dest = myserver:/home/vti/.backups/laptop/
    exclude = ignore-me
    hook-before = sh hooks/check-ssid.sh my_home_network

    [scenario:snapshot]
    type = snapshot
    period = */5 * * * *
    source = /home/vti/Documents/
    dest = /home/vti/.snapshots/

### Periods

Periods are cron-like schedules. The difference is that they are executed even
if the time of execution has passed because the machine was off for example,
this makes these periods suitable for using on laptops.

Here is how the decision is made:

1. Get the last time the scenario was run
2. If it was never run -> run immediately
3. If it was run long ago and the next execution time has passed -> run
   immediately
4. If it has to be run right now -> run immediately
5. Skip the scenario otherwise

If there is no period specified or `force` option is used the scenario is run
immediately.

### Encryption

GPG encryption is supported so far. In this case a `duplicity` is used and
a password is aditionally required. `source` and `dest` options have to be
changed in order to work with `duplicity` (I plan to make this easier and more
standard between rsync and duplicity).

    [scenario:mirror_with_encryption]
    type = mirror
    encryption = gpg
    password = mypassword
    source = /home/vti/.snapshots/
    dest = scp://myserver//home/vti/.backups/laptop/

## Installation

rmachine is available as a normal Perl distribution that can be installed using
`cpan` or `cpanm`, or as a fat packed file that can be copied to a
laptop or a remote server.

After getting rmachine, an install command should be run:

    $ rmachine install # TODO

This sets up a cron job and creates `~/.rmachine` directory where the default
config and log files are placed.

### System dependencies

- rsync
- ssh (if you want remote backups)
- duplicity (if you want encryption)

## Running

rmachine is meant to be run by cron, but for the testing or checking your
configuration it can be run just as a normal Perl script.

    $ rmachine --test
    2014-03-05T23:34:01.7586+0200 [scenario:snapshot] [start] 
    2014-03-05T23:34:01.8023+0200 [scenario:snapshot] [changes] No changes
    2014-03-05T23:34:01.8025+0200 [scenario:snapshot] [end] Success
    2014-03-05T23:34:01.8027+0200 [rmachine] [end] Finishing

### Command-line options

    --help    Print help on command-line options
    --version Print version an exit
    --test    Run in test or dry-run mode, when commands are not run
    --force   Run backups immediately, not check if the period is matched
    --quiet   Suppress the output (the important information is
                  still being written to the log file)
    --log     Path to the log file (`~/.rmachine/rmachine.log` by default)
    --config  Path to the config file (`~/.rmachine/rmachine.conf` by default)

### Log file

Log file is an important part of the system. It has to be configured. Every
line follows the same pattern:

    DATE [source] [action] Optional message

Log file tries to be dense, but all the errors are written AS IS for the ease
of investigation.

### Hooks

Hooks are scripts run during different phases of the execution.

    hook-before   Is run before the scenario is started, if the script
                  exits with non-zero status, rmachine skips this scenario,
                  this is the recommended way of canceling a scenario
    book-after    Is run after the scenario

## Ideas

### Inotify

I was thinking about using inotify, but that would require writing a robust
daemon with a watchdog script. And do you really want to make snapshots every
time you save a file? So I don't see this is as a high priority feature, but I
woudn't mind if someone helps me though ;)
