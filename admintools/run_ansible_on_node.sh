#!/bin/bash
if [[ -f /varidata/research/software/slurmPretty/admintools/tracking/$1 ]] ; then
	    echo lockfile for $1 already exits
	    exit
fi

touch /varidata/research/software/slurmPretty/admintools/tracking/$1
logger RECOVERY STARTED: admintools/run_ansible_on_node.sh $1
export PATH=$PATH:/cm/local/apps/cmd/bin:/usr/local/bin

if [[ $# -eq 0 ]] ; then
	echo 'specify a server'
	exit 0
fi

until  echo "checking $1" && sleep 10 && ssh $1 ls /var/log/cron
do
	echo `date` "node is still down"  2>&1 | tee -a /varidata/research/software/slurmPretty/admintools/tracking/$1
done
echo "node is now up"  2>&1 | tee -a /varidata/research/software/slurmPretty/admintools/tracking/$1

awx  --conf.insecure  --conf.host https://ansible.vai.org:8043 --conf.token wQW38k56KE6N7zHQJt9IZGpzLUjFfk job_templates launch --wait --limit $1.hpc.vai.org 12  2>&1 | tee -a /varidata/research/software/slurmPretty/admintools/tracking/$1
#sleep 60
#ssh $1  /varidata/research/clustermgmt/vaihpc/VAIDocker/hpcnode/restartcontainers.sh
sleep 10
rm /varidata/research/software/slurmPretty/admintools/tracking/$1

