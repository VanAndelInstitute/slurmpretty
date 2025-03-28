#!/usr/bin/env perl
use Net::SMTP;
use strict;

my $oom = `curl -u j6uv77ubc83majv1vbdj8tmunfcb3u6o915u39jn20of5jthnrr:token  -X GET -H 'Accept: application/json' "http://graylog.hpc.vai.org:9000/api/search/messages?query=out%20AND%20of%20AND%20memory%20AND%20UID&streams=65aa9fef6ab10b7345a88679&timerange=20m&fields=timestamp%2Cmessage"`;

my %seen;

while ($oom =~ /\"(20\d\d.+?)\".+?(server\d\d\d).+?Killed process (\d+) \((.+?)\).+?UID:(\d+)/g)
{
	my $date = $1;
	my $node = $2;
	my $pid = $3;
	my $process = $4;
	my $username = `id -un $5`;
	chomp $username;
	print "$date $node $pid $process $5 $username " . $seen{"$username $node"} . "\n";
	next if ($5 == 0 || $seen{"$username $node"} =~ /duplicate/);
	$seen{"$username $node"}="duplicate";

	my $warning = <<EOF

Dear $username,

Your HPC job running $process (pid $pid) at $date has triggered an "Out of Memory" error and is crashing. 
This error happens when your app or program attempts to use more RAM/memory than is available. Please verify your data and/or run on a larger compute node (if available). This is an automated message from the HPC job scheduler.

please open a help ticket with the HPC team if you have any questions: hpc3\@vai.org


EOF
;

	#&email("zack.ramjan\@vai.org","Warning: HPC Job running $process has trigged a memory error", $warning); 		
	&email("$username\@vai.org","Warning: HPC Job running $process has trigged a memory error", $warning); 		
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
