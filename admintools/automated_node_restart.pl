#!/usr/bin/perl
use Net::Ping;
my @down;

$slurmDeadNodesCmd = "docker exec slurm sinfo -dR -N -h";
$dockerPath = "/varidata/research/clustermgmt/vaihpc/VAIDocker/hpcnode";
$reloadScript = "/varidata/research/software/slurmPretty/admintools/reload_node_completely.sh";
for my $compute (`$slurmDeadNodesCmd`)
{
	$compute =~ /(compute\d+)/;
	$compute = $1;
	my $server = &computeToServer($compute);	
	push @down, $server unless &checkAlive($server);
}
exit unless $down[0];
my $serverToBounce = $down[rand @down];
my $downServers = join(" ",@down);

system "logger Servers down: $downServers. Choosing one to reboot: reload_node_completely.sh $serverToBounce\n";
system "/varidata/research/software/slurmPretty/admintools/reload_node_completely.sh  $serverToBounce";


sub computeToServer
{
	my $compute = shift @_;
	my $server = `grep $compute $dockerPath/*.yml | head -n 1`;
	$server =~ /(server\d\d\d)/;
	return $1;

}

for my $server (@ARGV)
{
	print &checkAlive($server) ? "$server is up\n" : "$server is down\n";
}

sub checkAlive {
	my $server = shift @_;
	my $pinger = Net::Ping->new('tcp');
	$pinger->port_number(22); 
	return $pinger->ping($server)
		
}

