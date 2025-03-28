#!/bin/bash
if [[ $# -eq 0 ]] ; then
	CONTAINER="$HOSTNAME"
else
	CONTAINER=$1
fi

BAREMETAL=`/varidata/research/software/slurmPretty/admintools/compute2server.pl $CONTAINER`

if [[ -f /varidata/research/software/slurmPretty/admintools/tracking/$CONTAINER ]] ; then
	    echo lockfile for $CONTAINER already exits
	    exit
fi

touch /varidata/research/software/slurmPretty/admintools/tracking/$CONTAINER
logger RECOVERY STARTED: admintools/rebootHostByComputeName.sh $CONTAINER in $BAREMETAL
export PATH=$PATH:/cm/local/apps/cmd/bin:/usr/local/bin
source /varidata/research/admin/awxcmdline/bin/activate
awx  --conf.insecure  --conf.host https://ansible.vai.org:8043 --conf.token zTCVIAwJibkRrTpk6pgLZCAoM0rH0X job_templates launch --wait --limit $BAREMETAL.hpc.vai.org 18  2>&1 | tee -a /varidata/research/software/slurmPretty/admintools/tracking/$CONTAINER
sleep 10
rm /varidata/research/software/slurmPretty/admintools/tracking/$CONTAINER

