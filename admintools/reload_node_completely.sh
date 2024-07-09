#!/bin/bash
if [[ -f /varidata/research/software/slurmPretty/admintools/tracking/$1 ]] ; then
	    echo lockfile for $1 already exits
	    exit
fi


if [[ $# -eq 0 ]] ; then
	echo 'specify a server'
	exit 0
fi
cmsh -c "device; use $1; power off " 2>&1 | tee /varidata/research/software/slurmPretty/admintools/tracking/$1
sleep 30
cmsh -c "device; use $1; power on"  2>&1 | tee -a /varidata/research/software/slurmPretty/admintools/tracking/$1
