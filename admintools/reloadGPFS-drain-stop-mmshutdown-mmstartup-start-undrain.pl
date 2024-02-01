#!/usr/bin/perl
#ZR
# this will restart a particular containerized compute node, it will detect which server its running on and restart the particular service
use Cwd 'abs_path';
use File::Basename;

my $EXECPATH = abs_path("/varidata/research/clustermgmt/vaihpc/VAIDocker/hpcnode");
my $dockerFile = do{local(@ARGV,$/)="$EXECPATH/Dockerfile";<>};
$SIG{INT} = \&tsktsk;
$baremetal = shift @ARGV || die "specify a host to drain all compute and restart GPFS";

my @computenodes = `grep -o -e compute[0-9][0-9][0-9] $EXECPATH/$baremetal-docker-compose.yml | sort | uniq`;
chomp @computenodes;;
die unless @computenodes;


runcmd("ssh $_ scontrol update nodename=$_ state=DRAIN reason=\"reload-GPFS\"") for @computenodes ;
runcmd("ssh $baremetal \"cd /varidata/research/clustermgmt/vaihpc/VAIDocker/hpcnode;  docker-compose -f $baremetal-docker-compose.yml rm -f -s $_ \"" ) for @computenodes;
runcmd("ssh $baremetal /usr/lpp/mmfs/bin/mmshutdown");
sleep 10;
runcmd("ssh $baremetal /usr/lpp/mmfs/bin/mmstartup");
sleep 20;
runcmd("ssh $baremetal /usr/lpp/mmfs/bin/mmmount research");
runcmd("ssh $baremetal /usr/lpp/mmfs/bin/mmmount researchtemp");
sleep 10;
runcmd("ssh $baremetal \"cd /varidata/research/clustermgmt/vaihpc/VAIDocker/hpcnode;  docker-compose -f $baremetal-docker-compose.yml up -d $_ \"" ) for @computenodes;
sleep 20;
runcmd("ssh $_ scontrol update nodename=$_ state=resume") for @computenodes;


sub runcmd{
	my $date = `date`;
	chomp $date;
        my $cmd=shift @_;
        my $caller=(caller(1))[3];
        print STDERR "$date\t$caller\t$cmd\n";
	system($cmd);
	sleep 1;
}
