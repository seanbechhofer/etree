#!/bin/sh

for index in $* 
do
    for x in ./files/$index/* 
    do
	echo $x
	pushd "$x"
	echo `wc performances.txt`
	cat performances.txt | while read LINE
	do
	    if [[ $LINE =~ "Artist: " ]]; then
		echo $LINE
	    else
		if [ -s ${LINE}_meta.xml ]; then
     	     	    echo ${LINE}_meta.xml exists
     		else
     	     	    wget http://www.archive.org/download/${LINE}/${LINE}_meta.xml 
     		fi
     		if [ -f ${LINE}_files.xml ]; then
     	     	    echo ${LINE}_files.xml exists
     		else
     	     	    wget http://www.archive.org/download/${LINE}/${LINE}_files.xml 
     		fi
	    fi
	done
	popd
    done
done
