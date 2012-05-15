#!/bin/sh

for x in $*
do
    mkdir files/$x
    ruby scripts/cli.rb -v -f data/artists-$x.txt -o ./files/$x getPerformanceIDs
done
