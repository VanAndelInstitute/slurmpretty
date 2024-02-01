#!/bin/bash
#Last checked, this was running as a cron job on utility002 with the assumption tha submit003 was hosted there.
BUCKET=hpc-dashboard
docker exec submit003 /varidata/research/software/slurmPretty/slurmnodez -f | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" > /tmp/slurmnodez.txt
docker exec submit003 /varidata/research/software/slurmPretty/zqueuefull -f | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" > /tmp/zqueue.txt
docker run --rm -t -v /tmp/slurmnodez.txt:/slurmnodez.txt -v /tmp/zqueue.txt:/zqueue.txt -v ~/.aws:/root/.aws amazon/aws-cli s3 cp /slurmnodez.txt s3://$BUCKET.aws.vai.org/data/slurmnodez.txt
docker run --rm -t -v /tmp/slurmnodez.txt:/slurmnodez.txt -v /tmp/zqueue.txt:/zqueue.txt -v ~/.aws:/root/.aws amazon/aws-cli s3 cp /zqueue.txt s3://$BUCKET.aws.vai.org/data/zqueue.txt

