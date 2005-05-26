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

#Don't change version manually
$::VERSION = '1.1-20mdk';

my $release_file = find { -f $_ } '/etc/mandrakelinux-release', '/etc/mandrake-release', '/etc/redhat-release';

sub get_release() {
    my ($release) = cat_($release_file) =~ /release\s+(\S+)/;
    ($release)
}

sub get_distro_type {
    my $release = cat_($release_file);
    my ($arch) = $release =~ /\s+for\s+(\w+)/;
    my ($name) = $release =~ /(corporate|mnf)/i;
    { name => lc($name), arch => $arch };
}

sub get_from_URL {
    my ($link, $agent_name) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent($agent_name . $ua->agent . $::VERSION);
    $ua->env_proxy;
    my $request = HTTP::Request->new(GET => $link);
    my $response = $ua->request($request);
    $response
}

sub get_site {
    my $link = shift;
    $link .= join('', @_);
    system("/usr/bin/www-browser  " . $link . "&");
}

sub subscribe_online {
    my ($full_link) = shift;
    my $ret = get_from_URL($full_link, "MdkOnlineAgent/");
    my $str;
    my $result = {
		  10 => 'OK',
		  11 => N("Login and password should be less than 12 characters\n"),
		  12 => N("Special characters are not allowed\n"),
		  13 => N("Please fill in all fields\n"),
		  14 => N("Email not valid\n"),
		  15 => N("Account already exists\n"),
		 };
    if ($ret->is_success) {
	my $content = $ret->content;
#	    print "CODE_RETOUR = $content\n";
	if ($content =~ m/(\d+)/) { my $code = sprintf("%d",$1); $str = $result->{$code} }
    } else { $str = N("Problem connecting to server \n") }
    $str
}

sub check_valid_email {
    my $email = shift;
    my $st = $email = ~/^[a-z][a-z0-9_\-]+(\.[a-z][a-z0-9_]+)?@([a-z][a-z0-9_\-]+\.){1,3}(\w{2,4})(\.[a-z]{2})?$/ix ? 1 : 0;
    return $st
}

sub rpm_ver_parse {
    my ($ver) = @_;
    my @verparts;
    while ($ver ne "") {
        if ($ver =~ /^([A-Za-z]+)/) {    # leading letters
            push(@verparts, $1);
            $ver =~ s/^[A-Za-z]+//;
        } elsif ($ver =~ /^(\d+)/) {       # leading digits
            push(@verparts, $1);
            $ver =~ s/^\d+//;
        } else {                             # remove non-letter, non-digit
            $ver =~ s/^.//;
        }
    }
    return @verparts;
}

sub rpm_ver_cmp {
    my ($a, $b) = @_;
    # list of version/release tokens
    my @aparts;
    my @bparts;
    # individual token from array
    my ($apart, $bpart, $result);
    if ($a eq $b) {
        return 0;
    }
    @aparts = rpm_ver_parse($a); 
    @bparts = rpm_ver_parse($b); 
    while (@aparts && @bparts) {
        $apart = shift (@aparts);
        $bpart = shift (@bparts);
	if ($apart =~ /^\d+$/ && $bpart =~ /^\d+$/) {    # numeric
            if ($result = $apart <=> $bpart) {
                return $result;
            }
        } elsif ($apart =~ /^[A-Za-z]+/ && $bpart =~ /^[A-Za-z]+/) {    # alpha
            if ($result = $apart cmp $bpart) {
                return $result;
            }
        } else {    # "arbitrary" in original code
	    my $rema = shift(@aparts);
	    my $remb = shift(@bparts);
	    if ($rema && !$remb) { return 1 } elsif (!$rema && $remb) { return -1 }
	    #return -1;
        }
    }
    # left over stuff in a or b, assume one of the two is newer
    if (@aparts) { return 1 } elsif (@bparts) {	return -1 } else { return 0 }
}

sub report_config {
    my $file = shift;  
sub header { "            
********************************************************************************
* $_[0]
********************************************************************************";
}
output($file, map { chomp; "$_\n" }
  header("rpm -qa"), join('', sort `rpm -qa`),
  header("mandrake version"), cat_($release_file));
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
    $ua->agent("MdkOnlineAgent" . '/' . $ua->agent . $::VERSION);
    $ua->env_proxy;
    my $response = $ua->request(POST $link,
				Content_Type => 'form-data',
                                Content => [ %$content ]);
    if ($response->is_success && $response->content =~ /^TRUE(.*?)([^a-zA-Z0-9].*)?$/) {
	($res, $key) = ('TRUE', $1);
    } 
    ($res, $key)
}

sub mv_files {
    my ($source, $dest) = @_;
    -e $source and system("mv", $source, $dest);
}

sub clean_confdir {
    my $confdir = '/root/.MdkOnline';
    system "/bin/rm", "-f", "$confdir/*log.bz2", "$confdir/*log.bz2.uue", "$confdir/*.dif $confdir/rpm_qa_installed_before", "$confdir/rpm_qa_installed_after";
}

sub hw_upload {
    my ($login, $passwd, $hostname) = @_;
    my $hw_exec = '/usr/sbin/hwdb_add_system';
    -x $hw_exec && !-s '/etc/sysconfig/mdkonline' and system("HWDB_PASSWD=$passwd $hw_exec $login $hostname &");
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
    output_with_perm $wideconf, 0644,
    qq(LOGIN=$login
MACHINE=$boxname
COUNTRY=$country
LASTCHECK=$d
);
}

sub is_running {
    my ($name) = @_;
    # Set USER environment variable if necessary:
    $ENV{USER} ||= getlogin || (getpwuid($<))[0];
    any {
	my ($ppid, $pid, $n) = /^\s*(\d+)\s+(\d+)\s+(.*)/;
	#- to run ps, perl may create some process with $name as name and 1 as ppid
	$ppid != 1 && $pid != $$ && $n eq $name;
    } `ps -o '%P %p %c' -u $ENV{USER}`;
}

1;
