#!/bin/bash

freeNodes=($(docker exec -t slurm /varidata/research/software/slurmPretty/slurmnodez|grep compute|grep FREE|awk '{print $1}'| sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'))
rand=$[$RANDOM % ${#freeNodes[@]}]
randomNode=$(echo ${freeNodes[$rand]}) 

echo Attempting reload on inactive node: $randomNode

output=$(/varidata/research/software/slurmPretty/admintools/drain-stop-restart-computenode.pl $randomNode)
$echo $output
