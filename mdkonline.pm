package mdkonline;

use strict;
use MIME::Base64 qw(encode_base64);

use lib qw(/usr/lib/libDrakX);
use c;
use common;

use LWP::UserAgent;         
use Net::HTTPS;
use HTTP::Request::Common;
use HTTP::Request;

sub get_release() {
    my ($release) = cat_('/etc/mandrake-release') =~ /release\s+(\S+)/;
    ($release)
}

sub get_from_URL {
    my ($link, $agent_name) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent($agent_name . $ua->agent);
    $ua->env_proxy;
    my $request = HTTP::Request->new(GET => $link);
    my $response = $ua->request($request);
    $response
}

sub subscribe_online {
    my ($full_link) = shift;
    my $ret = get_from_URL($full_link, "MdkOnlineAgent");
    my $str;
    my $result = {
		  10 => 'OK',
		  11 => N("Login and password should be less than 12 characters\n"),
		  12 => N("Special characters are not allowed\n"),
		  13 => N("Please fill in all fields\n"),
		  14 => N("Email not valid\n"),
		  15 => N("Account already exist\n"),
		 };
    if ($ret->is_success) {
	my $content = $ret->content;
#	    print "CODE_RETOUR = $content\n";
	if ($content =~ m/(\d+)/) { my $code = sprintf("%d",$1); $str = $result->{$code} }
    } else { $str = N("Problem connecting to server \n") }
    $str
}

sub report_config {
    my $file = shift;  
sub header { "            
********************************************************************************
* $_[0]
********************************************************************************";
}
output($file, map { chomp; "$_\n" }
  header("partitions"), cat_("/proc/partitions"),
  header("cpuinfo"), cat_("/proc/cpuinfo"),
  header("fstab"), cat_("/etc/fstab"),
  header("/etc/modules.conf"), cat_("/etc/modules.conf"),
  header("rpm -qa"), join('', sort `rpm -qa`),
  header("mandrake version"), cat_('/etc/mandrake-release'));
system("/usr/bin/bzip2 -f $file");
open(my $F, $file . ".bz2") or die "Cannot open file : $!";
my ($chunk, $buffer);
while (read($F, $chunk, 60*57)) {
    $buffer .= $chunk;
}
close($F);
open(my $OUT, "> $file" . ".bz2.uue") or die "Cannot open file : $!";
print $OUT encode_base64($buffer);
close($OUT);
}

sub send_config {
    my ($link, $content) = @_;
    my ($res, $key);
    my $ua = LWP::UserAgent->new;
    $ua->agent("MdkOnlineAgent/0.15" . $ua->agent);
    $ua->env_proxy;
    my $response = $ua->request(POST $link,
				Content_Type => 'form-data',
                                Content => [ %$content ]);
    if ($response->is_success && $response->content =~ /^TRUE(.*)/) {
	($res, $key) = ('TRUE', $1);
    } 
    ($res, $key)
}

sub mv_files {
    my ($source, $dest) = @_;
    -e $source and system("mv", $source, $dest);
}

sub automated_upgrades {
    my ($conffile, $login, $passwd, $boxname, $key, $country, $auto) = @_;
    my ($r) = get_release();
    output $conffile,
    qq(# automatically generated file. Please don't edit
LOGIN=$login
PASS=$passwd
MACHINE=$boxname
VER=$r
CURRENTKEY=$key 
COUNTRY=$country
AUTO=$auto
);  
    output_p "/etc/cron.daily/mdkupdate",
    qq(#!/bin/bash
if [ -f $conffile ]; then /usr/sbin/mdkupdate --auto; fi
);  
    
    chmod 0755, "/etc/cron.daily/mdkupdate";
}

sub write_wide_conf {
    my ($login, $boxname, $country) = @_;
    my $wideconf = '/etc/sysconfig/mdkonline';
    my $d = localtime();
    $d =~ s/\s+/_/g;
    output_with_perm $wideconf, 644,
    qq(LOGIN=$login
MACHINE=$boxname
COUNTRY=$country
LASTCHECK=$d
);
}

1;
