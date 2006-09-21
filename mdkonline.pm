################################################################################
# Mandriva Online functions                                                    # 
#                                                                              #
# Copyright (C) 2004-2005 Mandrakesoft                                         #
#               2005-2006 Mandriva                                             #
#                                                                              #
# Daouda Lo                                                                    #
# Thierry Vignaud <tvignaud at mandriva dot com>                               #
#                                                                              #
# This program is free software; you can redistribute it and/or modify         #
# it under the terms of the GNU General Public License Version 2 as            #
# published by the Free Software Foundation.                                   #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program; if not, write to the Free Software                  #
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.   #
################################################################################

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
use SOAP::Lite;
use log;

#For debugging
use Data::Dumper;

my ($service_proxy);

my $testing = 1;

my $release_file = find { -f $_ } '/etc/mandriva-release', '/etc/mandrakelinux-release', '/etc/mandrake-release', '/etc/redhat-release';
my ($product_file, $conf_file, $rootconf_file) = ('/etc/sysconfig/system', '/etc/sysconfig/mdkonline', '/root/.MdkOnline/hostconf'); 

my $uri = !$testing ? 'https://online.mandriva.com/soap' : 'https://online3.mandriva.com/soap/';

my $online_proxy = $service_proxy = $uri;

my $useragent = set_ua('mdkonline');

sub is_proxy () {
    return defined $ENV{http_proxy} ? 1 : defined $ENV{https_proxy} ? 2 : 0;
}

my $proxy = is_proxy();

my $s = $proxy == 2
  ? SOAP::Lite->uri($uri)->proxy($service_proxy, proxy => [ 'http' => $ENV{https_proxy} ], agent => $useragent) 
  : $proxy == 1 
  ? SOAP::Lite->uri($uri)->proxy($service_proxy, proxy => [ 'http' => $ENV{http_proxy} ], agent => $useragent) 
  : SOAP::Lite->uri($uri)->proxy($service_proxy, agent => $useragent);

sub upgrade2v3() {
    my $res;
    if (-e $rootconf_file) {
	my %oc = getVarsFromSh($rootconf_file);
	my $res = soap_recover_service($oc{LOGIN}, '{md5}' . $oc{PASS}, $oc{MACHINE}, $oc{COUNTRY});
	print Data::Dumper->Dump([ $res ], [qw(res)]);
	$res = check_server_response($res);
    }
    $res;
}

sub get_rpmdblist() {
    my $rpmdblist = `rpm -qa --queryformat '%{HDRID};%{N};%{E};%{V};%{R};%{ARCH};%{OS};%{DISTRIBUTION};%{VENDOR};%{SIZE};%{BUILDTIME};%{INSTALLTIME}\n'`;
    $rpmdblist;
}

sub md5file {
    require Digest::MD5;
    my @md5 = map {
        my $sum;
        if (open(my $FILE, $_)) {
            binmode($FILE);
            $sum = Digest::MD5->new->addfile($FILE)->hexdigest;
            close($FILE); 
        }
        $sum;
    } @_;   
    return wantarray() ? @md5 : $md5[0];
}

sub get_release() {
    my ($r) = cat_($release_file) =~ /release\s+(\S+)/;
    ($r);
}

sub set_ua {
    my $package_name = shift;
    my $qualified_name = chomp_(`rpm -q $package_name`);
    $qualified_name;
}

sub get_distro_type() {
    my $r = cat_($release_file);
    my ($archi) = $r =~ /\s+for\s+(\w+)/;
    my ($name) = $r =~ /(corporate|mnf)/i;
    { name => lc($name), 'arch' => $archi };
}

sub soap_create_account {
    my $data = $s->registerUser(@_)->result;
    log::explanations("creating account $_[0]");
    $data;
}

sub soap_authenticate_user {
    my $data = $s->authenticateUser(@_)->result; 
    log::explanations("authenticating account $_[0]");
    $data;
}

sub soap_register_host {
    my $data = $s->registerHost(@_)->result;
    log::explanations("registering host $_[3] named $_[4] in country $_[5]");
    $data;	
}

sub soap_upload_config {
    my $data = $s->setHostConfig(@_);
    log::explanations("uploading config for host id $_[0] host key $_[1] class $_[2]");
    $data ? $data->result : undef;
}

sub soap_query_bundle {
    my ($wc, $bundle_name) = @_;
    log::explanations("querying the bundle $bundle_name");
    my $data = $s->query($wc->{HOST_ID}, $wc->{HOST_KEY}, 'Software::get_bundle', $bundle_name)->result;
    $data;
}
sub register_upload_host {
    my ($login, $password, $boxname, $descboxname, $country) = @_;
    my ($registered, $res);
    my $wc = read_conf();
    if (!$wc->{HOST_ID} && -e $rootconf_file) {
	$res = upgrade2v3();
    } elsif (!$wc->{HOST_ID} && !-e $rootconf_file) {
	$registered = soap_register_host($login, $password, $boxname, $descboxname, $country);
	print Data::Dumper->Dump([ $registered ], [qw(registered)]);
	$res = check_server_response($registered);
    }
    return $res if defined $res && $res ne 'OK';
    #Reread configuration
    $wc = read_conf() if $res eq 'OK';
    $res = prepare_upload_conf($wc);
    $res;
}

sub prepare_upload_conf {
    my ($wc) = shift;
    my ($uploaded, $res);
    my $r = cat_($release_file); 
    my %p = getVarsFromSh($product_file); 
    my $rpmdblist = get_rpmdblist();
    $wc->{HOST_ID} and $uploaded = soap_upload_config($wc->{HOST_ID}, $wc->{HOST_KEY}, $r, $p{META_CLASS}, $rpmdblist);
    $res = check_server_response($uploaded);
    return $res;
}

sub get_from_URL {
    my ($link, $agent_name) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent($agent_name . $useragent);
    $ua->env_proxy;
    my $request = HTTP::Request->new(GET => $link);
    my $response = $ua->request($request);
    $response;
}

sub get_site {
    my $link = shift;
    $link .= join('', @_);
    system("/usr/bin/www-browser  " . $link . "&");
}

sub create_authenticate_account {
    my $type = shift;
    my @info = @_;
    my ($response, $ret);
    my $action = {
		  create => sub { eval { $response = soap_create_account(@info) } },
		  authenticate => sub { eval { $response = soap_authenticate_user(@info) } }
		 };
    $action->{$type}->();
    $ret = check_server_response($response);
    $ret;
}

sub check_server_response {
    my ($response) = shift;
    my $hash_ret = {
	   1  => [ N_("Security error"), N("Generic error (machine already registered)") ],                  
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
    foreach my $num ([9, 8], [21, 20]) { $hash_ret->{$num->[0]} = $hash_ret->{$num->[1]} }
    # print Data::Dumper->Dump([ $response ], [qw(response)]);
    my $code = $response->{code} || '99';
    my $answer = $response->{code} eq 0 ? 'OK' : $hash_ret->{$code} ? $hash_ret->{$code}[0] . ' : ' . $hash_ret->{$code}[1] . "\n\n" . $response->{message} : $response->{message};
    $answer eq 'OK' and write_conf($response) if !$<;
    log::explanations(qq(the server returned "$answer"));
    return $answer;
    
}

sub check_valid_email {
    my $email = shift;
    my $st = $email =~ /^[a-z][a-z0-9_\-]+(\.[a-z][a-z0-9_]+)?@([a-z][a-z0-9_\-]+\.){1,3}(\w{2,4})(\.[a-z]{2})?$/ix ? 1 : 0;
    return $st;
}

sub check_valid_boxname {
    my $boxname = shift;
    return 0 if length($boxname) >= 40;
    my $bt = $boxname =~ /^[a-zA-Z][a-zA-Z0-9_.]+$/i ? 1 : 0;
    $bt;
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

sub soap_recover_service {
    my $data = $s->recoverHostFromV2(@_)->result;
    $data;
}

sub soap_get_task {
    my $data = $s->getTask(@_)->result;
    $data;
}

sub soap_return_task_result {
    my $data = $s->setTaskResult(@_)->result;
    $data;	
}

sub soap_get_updates_for_host {
    my $data = $s->getUpdatesForHost(@_)->result;
    $data;
}

sub mv_files {
    my ($source, $dest) = @_;
    -e $source and system("mv", $source, $dest);
}

sub clean_confdir() {
    my $confdir = '/root/.MdkOnline';
    system "/bin/rm", "-f", "$confdir/*log.bz2", "$confdir/*log.bz2.uue", "$confdir/*.dif $confdir/rpm_qa_installed_before", "$confdir/rpm_qa_installed_after";
}

sub hw_upload {
    my ($login, $passwd, $hostname) = @_;
    my $hw_exec = '/usr/sbin/hwdb_add_system';
    -x $hw_exec && !-s '/etc/sysconfig/mdkonline' and system("HWDB_PASSWD=$passwd $hw_exec $login $hostname &");
}

sub automated_upgrades() {
    output_p "/etc/cron.daily/mdkupdate",
    qq(#!/bin/bash
if [ -f $conf_file ]; then /usr/sbin/mdkupdate --auto; fi
);  
    chmod 0755, "/etc/cron.daily/mdkupdate";
}

sub read_conf() {
    my %wc = getVarsFromSh($conf_file);
    \%wc;
}

sub write_conf {
    my $response = shift;
    write_wide_conf($response);
}

sub get_date() {
    my $date = `date --iso-8601=seconds`; # output  date/time  in ISO 8601 format. Ex: 2006-02-21T17:04:19+0100
    $date = chomp_($date);
    $date;
}

sub write_wide_conf {
    my ($soap_response) = shift;
    #print Data::Dumper->Dump([ $soap_response ], [qw(soap_response)]);
    my $date = get_date(); my $conf_hash;
    %$conf_hash = getVarsFromSh($conf_file);
    $conf_hash->{uc($_)} = $soap_response->{data}{$_} foreach keys %{$soap_response->{data}};
    #print Data::Dumper->Dump([ $conf_hash ], [qw(conf_hash)]);
    $conf_hash->{DATE_SET} = $date;
    foreach my $alias (['email', 'user_email'], ['customer_id', 'user_id']) {
	exists $conf_hash->{uc($alias->[0])} and $conf_hash->{uc($alias->[1])} = $conf_hash->{uc($alias->[0])};
    }
    setVarsInSh($conf_file, $conf_hash, qw(USER_EMAIL USER_ID HOST_NAME HOST_ID HOST_KEY HOST_DESC HOST_MOBILE VERSION DATE_SET));
}

sub is_running {
    my ($name) = @_;
    my $found;
    foreach (`ps -o '%P %p %c' -u $ENV{USER}`) {
        my ($_ppid, $pid, $n) = /^\s*(\d+)\s+(\d+)\s+(.*)/;
        if ($pid != $$ && $n eq $name) {
            $found = $pid;
            last;
        }
    }
    $found;
}

# Romain: you need to finish those dns functions or drop them
sub get_configuration {
    my $_in = shift;
    my $config_file = '/etc/sysconfig/mdkonline';
    my %conf;my $ret;
    # check local config file	
    if (! (-e $config_file) || ! (-s $config_file)) {
	%conf = get_conf_from_dns();
	print "from dns:\n", Dumper(%conf), "\n";
    } else {
	%conf = getVarsFromSh($config_file);
	if (defined $conf{MACHINE} && !defined $conf{VERSION}) {
	    $ret = upgrade_to_v3();
	    print "\n", $ret, "\n";
	    if ($ret == 1) {
		# reload config
		%conf = getVarsFromSh($config_file);
	    }
	    else {
		# TODO what do we do now? email warning? support? forget it?
		%conf = undef;
	    }
	}
    }
    
    # now, a valid working config file is loaded
    if (defined $conf{MOBILE} && $conf{MOBILE} eq 'TRUE') {
	# client is mobile: we check for any dns-declared local option
	# (like, a local update mirror)
	# TODO set precedence rules. user may not want/have the right to
	# follow local network rules (security of the update process).
	# depends on host config, and on server commands.
	my $sd   = new Discovery;
	my $info = $sd->search;
	if ($info) {
	    # TODO
	}
	else {} # nothing to do
    }
    %conf;
}

sub register_from_dns {
    my $dnsconf = shift;
    my ($hostinfo, $country );
    my $user = $dnsconf->{user}{name};
    my $pass = $dnsconf->{user}{pass};
    my $hostname = chomp_(`hostname`);
    # TODO change SOAP proxy to the one indicated at $dnsconf->{service} before
    # TODO wrap all soap calls into an object so we can update the proxy on the fly?
    my $res = mdkonline::soap_register_host($user, $pass, $hostname, $hostinfo, $country);
    if ($res->{code}) {
	$res->{data}{service} = $dnsconf->{service};
	return mdkonline::save_config($res->{data});
    }
}

sub get_conf_from_dns() {
    my $sd   = new Discover;
    my $info = $sd->search;
    my $ret;
    if ($info) {
	if (defined $info->{user}{name} && defined $info->{user}{pass} && $info->{user}{name} ne '' && $info->{user}{pass} ne '') {
         #print Data::Dumper->Dump([ $info ], [qw(info)]);
	    # TODO check service certificate
	    $ret = mdkonline::register_from_dns($info);
	    if ($ret) {
		return $ret;
	    }
	}
    }
}

1;
