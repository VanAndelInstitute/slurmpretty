#!/usr/bin/env perl
use strict;
my $cpuUtilizationCutoff = 0.20;
my $memUtilizationCutoff = 0.20;
my $threadsUtilizationCutoff = 35;
my $idleLimitHours = 4;
my $idleLimitMin = 60 * $idleLimitHours;

my @partitions = qw/big bigmem gpu/;

for my $p (@partitions)
{
	&checkJob($_) for &getJobsForPartition($p);
}


sub getJobsForPartition
{
	my $partition = shift @_ || die;
	my @jobs = `squeue -p $partition -h -o \%A`;
	chomp @jobs;
	return @jobs;
}

sub checkJob
{
	my $jobID = shift @_ || die;

	#get the running time of the job
	my $jobData = `scontrol -o show jobid  $jobID`;
	$jobData =~ /\s+RunTime=(\S+)\s+/;
	# ex: 00:39:10   or   8-23:14:07
	my $timeString = $1;

	#convert total run time to hours (rounded)
	$timeString =~ /^(\d+)-(\d\d):(\d\d):(\d\d)$/;
	my $days = $1 * 24 || 0;
	$timeString =~ /(\d\d):(\d\d):(\d\d)$/;
	my $hours = $1 + $days ;

	#get User of job
	$jobData =~ /\sUserId=([\w\.]+)/;
	my $userId = $1;

	system("logger checking $1 that has been running for $hours hours");
	if($hours >= $idleLimitHours && $jobData =~ /\s+NodeList=(compute\d\d\d)\s+/)
	{
		my $node = $1;

		#get number of cores on node;
		my $nodeData = `scontrol show node $node -o`;
		$nodeData =~ /CPUTot=(\d+)/;
		my $nodeCores=$1;
		
		#get the docker stats history for last minutes
		my @dockerHistory = `cd /varidata/research/software/slurmPretty/cpulogs; find ./ -mmin -$idleLimitMin | xargs ls -rt | xargs  grep $node`;
		chomp @dockerHistory;
		
		my $loadSum=0;
		my $loadCount=0;
		my $maxLoad=0;
		my $maxMem=0;
		my $maxThreads=0;
		
		my $dockerStatOutput = join("\n",@dockerHistory);
		#track the usage over the last time period
		for my $line (@dockerHistory)
		{
			$loadCount++;
			my @dockerStatCols = split(/\s+/,$line);
			$dockerStatCols[3] =~ s/\%//g;
			my $cpuUsage =  ($dockerStatCols[3] / 100);
			$loadSum += $cpuUsage;
			$maxLoad = $cpuUsage if $maxLoad < $cpuUsage;

			$dockerStatCols[7] =~ s/\%//g;
			my $memUsage = ($dockerStatCols[7] / 100);
			$maxMem = $memUsage if $maxMem < $memUsage;

			$maxThreads = $dockerStatCols[14];

		}
		my $utilization = $maxLoad / $nodeCores;
		system("logger \t$userId\@$node: peakload=$maxLoad /  $nodeCores = $utilization, peakmem=$maxMem, peakThreads=$maxThreads"); 
		
		if ($utilization < $cpuUtilizationCutoff && $maxMem < $memUtilizationCutoff && $maxThreads < $threadsUtilizationCutoff)
		{
			#get the job script
			$jobData =~ /\s+Command=(\S+)\s+/;
			my $command = $1;
			$command = `cat $command | head -n 100` if -f $command;

			system("logger \t\tWARN_IDLE $jobID $node $userId"); 
			my $ps = `ssh $node  ps ax o user:32,pid,pcpu,pmem,vsz,rss,stat,start_time,time,cmd | grep $userId | grep -v sshd | grep -v /var/spool/slurm`;
			my $warning = <<EOF
Dear $userId,

To ensure HPC resources are used fairly and not wasted, the system automatically detects jobs that may be considered wasteful, incorrectly sized, or abusive. Please understand HPC is a community resource, improper usage can impact other users. Note that these limits only apply to the public partitions, private nodes owned directly by a lab are not enforced or monitored for efficiency. 

- Idle jobs that are occupying a node but not doing anything are not allowed
- Jobs that attempt to "reserve" or "keep" nodes by performing trivial tasks to artificially  inflate cpu usage to appear "busy" are not allowed. 
- Undersized jobs that only use a small amount of resource but are allocated to nodes with large resources are wasteful and not allowed. These jobs should be put on a node that best matches the job requirements. For example, a job that only utilizes a few cores should never but run on a 128core node, and instead should use one of the smaller nodes from either the quick or short partitions. 


The system has detected that your job $jobID running on $node has been excessively idle for an extended period of time and has very poor utilization. Please immediately address this issue and/or resubmit it to a more appropriate partition. Wasteful Jobs that continue to run after being warned will be terminated. Continued misuse of the cluster may result in automatic deprioritization of your jobs.


please open a help ticket with the HPC team if you have any questions: hpc3\@vai.org










TRACKING INFO:
#####################################################

PROCESS OUTPUT
$ps
---------------------------------

JOB INFO
$jobData
---------------------------------

JOB SCRIPT
$command
---------------------------------

NODE INFO
$nodeData
---------------------------------

HOST INFO
$dockerStatOutput

EOF
;
	
		&email("$userId\@vai.org","Warning: HPC Job $jobID on $node, improper usage detected", $warning); 		
		#&email("zack.ramjan\@vai.org","Warning: HPC Job $jobID on $node, improper usage detected", $warning); 		

		}
		else
		{
			system("logger \t\tJob OK $jobID");
		}
	}
	else
	{
		system("logger \t$userId:$jobID: Skipping"); 
	}
}

sub email 
{
	my $to = shift @_;
	my $subject = shift @_;
	my $body = shift @_;

	#open(my $MAIL, "|/usr/bin/mail -r hpc3\@vai.org -b cdd89583.vai.org\@amer.teams.ms -s \"$subject\" $to") or die ("Can't sendmail - $!");
	open(my $MAIL, "|/usr/bin/mail -r hpc3\@vai.org -s \"$subject\" $to") or die ("Can't sendmail - $!");
	print $MAIL $body;
	close($MAIL);
}
