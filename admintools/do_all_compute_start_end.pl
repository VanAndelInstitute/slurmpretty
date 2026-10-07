#!/usr/bin/perl
#
$SIG{INT} = \&tsktsk;

if($ARGV[0] =~ /^\d+/)
{
	$start = shift @ARGV || -1;
	$end = shift @ARGV || -1;
}
if(!$start)
{
	
	@nodelist = `sinfo -N -o "%N" | sort | uniq` if -e "/.dockerenv";
	@nodelist = `docker exec slurm sinfo -N -o "%N" | sort | uniq` unless -e "/.dockerenv";
	chomp @nodelist;
	push(@nodelist,qw/submit001 submit002 submit002 ondemand1 ondemand2 ondemand3/);
}
else
{
	for my $n ($start..$end)
	{
	    $n = "00$n" if ($n <= 9);
	    $n = "0$n" if ($n >= 10 && $n < 100);
	    push(@nodelist,"compute$n");
	}
}

#print "$_\n" for @nodelist;


sub tsktsk {
      $SIG{INT} = \&tsktsk;           # See ``Writing A Signal Handler''
      exit 0;
        }

for my $compute (@nodelist)
{
     next if system("ping -c 1 -W .1  $compute");

	print STDERR "$compute:\n";
	system("ssh -q -o \"StrictHostKeyChecking no\" root\@$compute \"" . join(" ",@ARGV) . "\"" );
	print  "\n";
	sleep 1;
}

