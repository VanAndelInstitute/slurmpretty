#!/usr/bin/perl

my $compute = shift @ARGV || die "supply a compute container and I will give you the server it runs on\n";

$dockerPath = "/varidata/research/clustermgmt/vaihpc/VAIDocker/hpcnode";
my $server = &computeToServer($compute);	
print "$server\n";
sub computeToServer
{
	my $compute = shift @_;
	my $server = `grep $compute $dockerPath/*.yml | head -n 1`;
	$server =~ /(server\d\d\d)/;
	return $1;

}


