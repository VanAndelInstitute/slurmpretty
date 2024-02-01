#!/usr/bin/perl
#ZR
# this will restart a particular containerized compute node, it will detect which server its running on and restart the particular service
use Cwd 'abs_path';
use File::Basename;

my $EXECPATH = abs_path("/varidata/research/clustermgmt/vaihpc/VAIDocker/hpcnode");
my $dockerFile = do{local(@ARGV,$/)="$EXECPATH/Dockerfile";<>};
$SIG{INT} = \&tsktsk;
$compute = shift @ARGV || die "specify a compute node to drain and restart";;

my $baremetal = `grep -l $compute $EXECPATH/server*yml`;
chomp $baremetal;
$baremetal =~ /(server\d\d\d)/ || die "could not determine bare metal docker server";
$baremetal = $1;

runcmd("ssh $baremetal docker exec -t $compute systemctl restart sshd"); 
runcmd("ssh $compute hostname "); 


sub runcmd{
	my $date = `date`;
	chomp $date;
        my $cmd=shift @_;
        my $caller=(caller(1))[3];
        print STDERR "$date\t$caller\t$cmd\n";
	system($cmd);
}
