#!/bin/sh

set -v
for x in artists-*-to-*.txt 
do
    base=`basename $x .txt`
    ruby align-artists.rb -i $base.txt -o $base.yml
done
