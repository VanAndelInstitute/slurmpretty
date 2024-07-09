#!/usr/bin/perl
#

while(my $line = <>)
{
	if($line =~ /UID.(\d+)/)
	{
		$name = uid2name($1);
		$line =~ s/$uid/$name/g
	}
	print $line;
}

sub uid2name
{
	$uid = shift @_;
	unless($name{$uid})
	{
		`id $uid` =~ /uid=\d+\((\w+\.\w+)\)/;
		$name{$uid} =  $1;
	}
	return $name{$uid};
}
