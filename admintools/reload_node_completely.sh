#!/bin/bash
if [[ -f /varidata/research/software/slurmPretty/admintools/tracking/$1 ]] ; then
	    echo lockfile for $1 already exits
	    exit
fi

touch /varidata/research/software/slurmPretty/admintools/tracking/$1
logger RECOVERY STARTED: admintools/reload_node_completely.sh $1
export PATH=$PATH:/cm/local/apps/cmd/bin:/usr/local/bin

if [[ $# -eq 0 ]] ; then
	echo 'specify a server'
	exit 0
fi
cmsh -c "device; use $1; power off"
sleep 30
cmsh -c "device; use $1; power on"
sleep 300


until  echo "checking $1" && sleep 10 && ssh $1 ls /var/log/cron
do
	echo `date` "node is still down"
done
echo "node is now up"

awx  --conf.insecure  --conf.host https://ansible.vai.org:8043 --conf.token vJD0UeJV33520U9IGEq7uaBQs87bDp job_templates launch --wait --limit $1.hpc.vai.org 12
sleep 60
ssh $1  /varidata/research/clustermgmt/vaihpc/VAIDocker/hpcnode/restartcontainers.sh
sleep 10
rm /varidata/research/software/slurmPretty/admintools/tracking/$1

