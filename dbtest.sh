#!/bin/bash

dbloc=/mnt/carbon-steel/ingested/collector_db/collector.sqlite

for i in `seq -f "%02g" 1 12`; do
	for directory in $(ls -d ~/ingested/201[6-9]-$i*/* | egrep -v '.tar|.gz'); do
		sqlite3 $dbloc "insert into collectors (date,path,machinesig) values (\"$(echo $directory | cut -d/ -f5)\",\"$(echo $directory)\",\"$(echo $directory | cut -d- -f6)\")"
		echo $directory
#		echo $(echo $directory | cut -d/ -f5)
#		echo $(echo $directory | cut -d- -f6)
	done
done
