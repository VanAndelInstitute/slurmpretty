#!/usr/bin/env perl


for my $user (@ARGV)
{
	my $exists = int(`sacctmgr -n list user $user| wc -l`);
	print STDERR "USER $user  already exists\n "if $exists;
	next if $exists;
	die "/home/$user does not exists, is this a real user?\n" if ! -e "/home/$user";
	runcmd("sacctmgr -i add user $user account=hpcusers"); 

}
sub runcmd{
        my $cmd=shift @_;
        my $caller=(caller(1))[3];
        print STDERR "$caller\t$cmd\n";
        system("$cmd 2>&1 | tee -a $WORKDIR/cmd.log") if !$DEBUG;
}

