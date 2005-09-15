package mdkonline;

use strict;
use MIME::Base64 qw(encode_base64);

use lib qw(/usr/lib/libDrakX);
use c;
use common;
use SOAP::Lite;

my $release_file = find { -f $_ } '/etc/mandriva-release', '/etc/mandrakelinux-release', '/etc/mandrake-release', '/etc/redhat-release';
my $uri = 'https://my.mandriva.com/soap/';
my $serviceProxy = 'https://my.mandriva.com/soap/';
my $onlineProxy = 'https://onine.mandriva.com/soap';

my $useragent = set_ua('mdkonline');

my $s = is_proxy() ? SOAP::Lite->uri($uri)->proxy($serviceProxy, proxy => [ 'http' => $ENV{http_proxy} ], agent => $useragent) : SOAP::Lite->uri($uri)->proxy($serviceProxy, agent => $useragent);

sub is_proxy () {
    return 1 if defined $ENV{http_proxy};
}

sub get_release() {
    my ($release) = cat_($release_file) =~ /release\s+(\S+)/;
    ($release)
}

sub set_ua {
    my $package_name = shift;
    my $qualified_name = chomp_(`rpm -q $name`);
    $qualified_name
}

sub get_distro_type {
    my $release = cat_($release_file);
    my ($arch) = $release =~ /\s+for\s+(\w+)/;
    my ($name) = $release =~ /(corporate|mnf)/i;
    { name => lc($name), arch => $arch };
}

sub soap_create_account {
    my $register = $s->registerUserFromWizard(@_)->result();
    $register;
}

sub soap_authenticate_user {
    my $auth = $s->authenticateUser(@_)->result(); 
    $auth
}

sub get_from_URL {
    my ($link, $agent_name) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent($agent_name . $useragent);
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
    my ($type) = shift;
    my ($response, $code);
    my $hreturn = {
                   1  => [ N("Security error"), N("Unsecure invocation: Method available through httpS only") ],                  
                   2  => [ N("Database error"), N("Server Database failed\nPlease Try again Later") ],
		   3  => [ N("Registration error"), N("Some parameters are missing") ],
                   5  => [ N("Password error"), N("Wrong password") ],
                   7  => [ N("Login error"), N("The email you provided is already in use\nPlease enter another one\n") ],         
                   8  => [ N("Login error"), N("The email you provided is invalid or forbidden") ],
		  10  => [ N("Login error"), N("Email address box is empty\nPlease provide one") ],
		  12  => [ N("Restriction Error"), N("Database access forbidden") ],
                  13  => [ N("Service error"), N("Mandriva web services are currently unavailable\nPlease Try again Later") ],    
                  17  => [ N("Password error"), N("Password mismatch") ],
		  20  => [ N("Service error"), N("Mandriva web services are under maintenance\nPlease Try again Later") ],        
                  22  => [ N("User Forbidden"), N("User account forbidden by Mandriva web services") ],
		  99  => [ N("Connection error"), N("Mandriva web services not reachable") ]
                  };  
    foreach my $num ([9, 8], [21, 20]) { $hreturn->{$num->[0]} = $hreturn->{$num->[1]} };
    my $action = {
		  create => sub {
		      eval { $response = $this->soap_create_account(@_) };
		      if ($response->{status}) {
			  return 'OK'
		      } else {
			  $code = $this->{response}{code} || '99';
			  return $hreturn->{$code}->[0] . ' : ' . $hreturn->{$code}->[1];
		      },
		  }
		  authenticate => sub {
		      eval { $response = $this->soap_authenticate_user(@_) };
		      if ($response->{status}) {
			  return 'OK'
		      } else {
			  $code = $this->{response}{code} || '99';
			  return $hreturn->{$code}->[0] . ' : ' . $hreturn->{$code}->[1];
		      },
		  }
		 };
    $action->{$type}->();
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
    $ua->agent($useragent);
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
    any {
        my ($ppid, $pid, $n) = /^\s*(\d+)\s+(\d+)\s+(.*)/;
        $pid != $$ && $n eq $name;
    } `ps -o '%P %p %c' -u $ENV{USER}`;
}

1;
