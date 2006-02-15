#!/usr/bin/perl -w

my $bundle = $ARGV[0];

$bundle or die ("no bundles avalailable");

$bundle =~ /\.bundle$/ and exec("/usr/sbin/mdkupdate --bundle $bundle");
