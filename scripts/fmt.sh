#!/bin/bash

DIR=`dirname $0`
ROOT=$DIR/..

# Format code in project.

perltidy                                                                      \
    -l=79                                                                     \
    -b -bext='/'                                                              \
    $ROOT/example.pl                                                          \
    $ROOT/Geo-IPinfo/t/*                                                      \
    $ROOT/Geo-IPinfo/lib/Geo/*
