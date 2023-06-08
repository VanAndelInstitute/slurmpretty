#!/usr/bin/env perl
use strict;
my $cpuUtilizationCutoff = 0.15;
my $memUtilizationCutoff = 0.15;
my $idleLimitHours = 8;
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

		}
		my $utilization = $maxLoad / $nodeCores;
		system("logger \t$userId\@$node: peakload=$maxLoad /  $nodeCores = $utilization, peakmem=$maxMem"); 
		
		if ($utilization < $cpuUtilizationCutoff && $maxMem < $memUtilizationCutoff)
		{
			system("logger \t\tKILL_IDLE $jobID $node $userId"); 
			system("logger \t\tscancel $jobID");
	
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
