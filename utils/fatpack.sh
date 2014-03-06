#!/bin/sh

PERL5LIB="lib:$PERL5LIB"

fatpack trace bin/rmachine
fatpack packlists-for `cat fatpacker.trace` > packlists
fatpack tree `cat packlists`
fatpack file bin/rmachine > rmachine-one-file

rm -rf fatlib/
rm -f fatpacker.trace
rm -f packlists
