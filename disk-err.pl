#!/usr/bin/perl -w

$pwd=`pwd`;
open my $log, "-|", "gzip", "-d", $pwd."/fma/fmdump-evt-30day.out.gz" or 
    open my $log, "$pwd./fma/fmdump-evt-30day.out" or die "couldn't open $!";

my @diskerrs = `less fma/fmdump-evt-30day.out.gz | egrep "^[A-Z].*disk.*|device" | sed -e "s/^.*device-path.*disk@\(.*\),0/\1/"`;
my %errors;
my $key;
while ($line = <log>) {
    chomp($line);
    if ($line =~ /^[A-Z].*disk.*/) {
        ($key) = $line;
        $errors{$key} = [];
    } elsif ($line =~ /device/) {
        $line = s/^.*device-path.*disk@//;
        $line = s/,.//;
        $line = `grep -A7 $line disk/hddisco.out | grep target_port | cut -d " " -f 3`;
        chomp $line;
        push @{ $errors{$key} }, $line;
    }
}
print "$_ $errors{$_}\n" for (keys %errors);
