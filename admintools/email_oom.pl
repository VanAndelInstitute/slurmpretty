#!/usr/bin/env perl
use Net::SMTP;
use strict;

my $oom = `curl -u 1f92pc0bg8efn5dkr6tj5me1gemiql3dn50p9f47afvcf1r3i0m3:token  -X GET -H 'Accept: application/json' "http://graylog.hpc.vai.org:9000/api/search/messages?query=out%20AND%20of%20AND%20memory%20AND%20UID&streams=65aa9fef6ab10b7345a88679&timerange=1h&fields=timestamp%2Cmessage"`;


while ($oom =~ /(compute\d\d\d).+?Killed process \d+ \((.+?)\).+?UID:(\d+)/g)
{
	my $node = $1;
	my $process = $2;
	my $username = `id -un $3`;
	chomp $username;
	print "$1 $2 $3 $username \n";
	my $warning = <<EOF

Dear $username,

Your HPC job running $process on $node has triggered an "Out of Memory" error and may be crashing. 
This error happens when your app or program attempts to use more RAM/memory than is available. You may want to verify your data and/or run on a larger compute node (if available). This is an automated message from the HPC job scheduler.

please open a help ticket with the HPC team if you have any questions: hpc3\@vai.org


EOF
;

#	&email("zack.ramjan\@vai.org","Warning: HPC Job on $node has trigged a memory error", $warning); 		
	&email("$username\@vai.org","Warning: HPC Job on $node has trigged a memory error", $warning); 		
}

sub email 
{
        my $to = shift @_;;
        my $from = "hpc3\@vai.org";
        my $subject = shift @_;
        my $message = shift @_;
        my $smtp = Net::SMTP->new('smtp.vai.org');
        $smtp->mail($from);
        if ($smtp->to($to)) {
             $smtp->data();
             $smtp->datasend("To: $to\n");
             $smtp->datasend("Subject: $subject\n");
             $smtp->datasend("$message\n");
             $smtp->dataend();
            } else {
             print "Error: ", $smtp->message();
            }
            $smtp->quit;
           system("logger $subject");
}
