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

#For debugging
use Data::Dumper;

my ($uri, $service_proxy, $online_proxy);
my $release_file = find { -f $_ } '/etc/mandriva-release', '/etc/mandrakelinux-release', '/etc/mandrake-release', '/etc/redhat-release';
my ($product_file, $conf_file, $rootconf_file) = ('/etc/sysconfig/system', '/etc/sysconfig/mdkonline', '/root/.MdkOnline/hostconf'); 
my $release = get_release();

#$uri = 'https://localhost/~romain/online3/htdocs/soap';
my $uri = 'https://online.mandriva.com/soap';
$uri = 'http://online3.mandriva.com/o/soap/';
$service_proxy = $online_proxy  = $uri;

my $useragent = set_ua('mdkonline');

sub is_proxy () {
    return defined $ENV{http_proxy} ? 1 : defined $ENV{https_proxy} ? 2 : 0;
}

my $proxy = is_proxy;

my $s = $proxy == 2
  ? SOAP::Lite->uri($uri)->proxy($service_proxy, proxy => [ 'http' => $ENV{https_proxy} ], agent => $useragent) 
  : $proxy == 1 
  ? SOAP::Lite->uri($uri)->proxy($service_proxy, proxy => [ 'http' => $ENV{http_proxy} ], agent => $useragent) 
  : SOAP::Lite->uri($uri)->proxy($service_proxy, agent => $useragent);

sub get_configuration {
    my $in = shift;
    my $config_file = '/etc/sysconfig/mdkonline';
    my %conf;my $ret;
    # check local config file	
    if( ! ( -e $config_file ) || ! ( -s $config_file ) ) {
	%conf = get_conf_from_dns();
	print "from dns:\n",Dumper(%conf),"\n";
    } else {
	%conf = getVarsFromSh($config_file);
	if( defined $conf{MACHINE} && ! defined $conf{VERSION} ) {
	    $ret = upgrade_to_v3();
	    print "\n", $ret, "\n";
	    if( $ret eq 1 ) {
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
    if( defined $conf{MOBILE} && $conf{MOBILE} eq 'TRUE' ) {
	# client is mobile: we check for any dns-declared local option
	# (like, a local update mirror)
	# TODO set precedence rules. user may not want/have the right to
	# follow local network rules (security of the update process).
	# depends on host config, and on server commands.
	my $sd   = new Discovery;
	my $info = $sd->search();
	if( $info ) {
	    # TODO
	}
	else {} # nothing to do
    }
    %conf;
}

# update current configuration values with those passed as argument
sub save_config {
    my $params = shift;
    my %current = getVarsFromSh('/etc/sysconfig/mdkonline');
    print Dumper($params);
    foreach my $l (qw(customer_id host_id host_key host_name country mobile auto)) {
	my $u = uc($l);
	$current{$u} = $params->{$l} if defined $params->{$l}
    }
    $current{VERSION} ||= 3;
    $current{DATE_SET} = chomp_(`LC_ALL=C date`);
    
    print Dumper(%current);
    print setVarsInSh( '/etc/sysconfig/mdkonline', %current );
    %current;
};

sub upgrade_to_v3 {
    my $oldconffile = '/root/.MdkOnline/mdkupdate';
    if( ( -e $oldconffile ) && ( -s $oldconffile ) ) {
	my %old = getVarsFromSh('/root/.MdkOnline/mdkupdate');
	if( $old{LOGIN} ne '' && $old{PASS} ne '' && $old{MACHINE} ne '' ) {
	    my $res = mdkonline::soap_recover_service($old{LOGIN},'{md5}'.$old{PASS},$old{MACHINE},$old{COUNTRY});
	    if( $res->{code} eq '0' || $res->{code} == 0 ) {
		my $cd = $res->{data};
		$cd->{auto}    = 'FALSE';
		$cd->{mobile}  = 'FALSE';
		$cd->{country} = '';
		$cd->{service} = 'https://online.mandriva.com/service';
		save_config( $res->{data} );
		return 1;
	    }
	    else {
	    }
	}
	else {
	}
    }
    else {
    }
}

sub register_from_dns {
    my $dnsconf = shift;
    my ($hostinfo, $country );
    my $user = $dnsconf->{user}->{name};
    my $pass = $dnsconf->{user}->{pass};
    my $hostname = chomp_(`hostname`);
    # TODO change SOAP proxy to the one indicated at $dnsconf->{service} before
    # TODO wrap all soap calls into an object so we can update the proxy on the fly?
    my $res = mdkonline::soap_register_host( $user, $pass, $hostname, $hostinfo, $country );
    if ($res->{code}) {
	$res->{data}->{service} = $dnsconf->{service};
	return mdkonline::save_config( $res->{data} );
    }
}

sub get_conf_from_dns {
    my $sd   = new Discover;
    my $info = $sd->search();
    my $ret;
    if( $info ) {
	if( defined $info->{user}->{name} && defined $info->{user}->{pass} && $info->{user}->{name} ne '' && $info->{user}->{pass} ne '' ) {
	    print Dumper($info);
	    # TODO check service certificate
	    $ret = mdkonline::register_from_dns( $info );
	    if( $ret ) {
		return $ret;
	    }
	}
    }
}

sub get_rpmdblist {
    my $rpmdblist = `rpm -qa --queryformat '%{HDRID};%{N};%{E};%{V};%{R};%{ARCH};%{OS};%{DISTRIBUTION};%{VENDOR};%{SIZE};%{BUILDTIME};%{INSTALLTIME}\n'`;
    $rpmdblist
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
    ($r)
}

sub set_ua {
    my $package_name = shift;
    my $qualified_name = chomp_(`rpm -q $package_name`);
    $qualified_name
}

sub get_distro_type {
    my $r = cat_($release_file);
    my ($arch) = $r =~ /\s+for\s+(\w+)/;
    my ($name) = $r =~ /(corporate|mnf)/i;
    { name => lc($name), arch => $arch };
}

sub soap_create_account {
    my $register = $s->registerUser(@_)->result();
    $register;
}

sub soap_authenticate_user {
    my $auth = $s->authenticateUser(@_)->result(); 
    $auth;
}

sub soap_register_host {
    my $auth = $s->registerHost(@_)->result();
    $auth;	
}

sub soap_upload_config {
    my $auth = $s->setHostConfig(@_)->result();
    $auth;	
}

sub register_upload_host {
    my ($login, $password, $boxname, $descboxname, $country) = @_;
    my ($registered, $uploaded);
    my ($rc, $wc) = read_conf();
    if (!$rc->{HOST_ID}) {
	$registered = soap_register_host($login, $password, $boxname, $descboxname, $country);
	$registered->{status} and write_conf($registered);
	($rc, $wc) = read_conf();
    }
    my $r = cat_($release_file);
    my %p = getVarsFromSh($product_file);
    my $rpmdblist = get_rpmdblist();
    $rc->{HOST_ID} and $uploaded = soap_upload_config($rc->{HOST_ID}, $rc->{HOST_KEY}, $r, $p{META_CLASS}, $rpmdblist);
    write_conf($uploaded);
    return 'TRUE'
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

sub create_authenticate_account {
    my $type = shift;
    my @info = @_;
    my ($response, $code, $ret);
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
		  create => sub { eval { $response = soap_create_account(@info) }; },
		  #create => sub { eval { $response = soap_exec_action('registerUser', @info) }; },
		  authenticate => sub { eval { $response = soap_authenticate_user(@info) }; }
		  #authenticate => sub { eval { $response = soap_exec_action('authenticateUser', @info) }; }
		 };
    $action->{$type}->();
    $ret = check_server_response($response, $hreturn);
    $ret;
}

sub check_server_response {
    my ($response, $h) = @_;
    print Dumper($response);
    my $code = $response->{code} || '99';
    $response->{status} and write_conf($response);
    return $response->{status} ? 'OK' : $h->{$code}->[0] . ' : ' . $h->{$code}->[1];
}

sub check_valid_email {
    my $email = shift;
    my $st = $email = ~/^[a-z][a-z0-9_\-]+(\.[a-z][a-z0-9_]+)?@([a-z][a-z0-9_\-]+\.){1,3}(\w{2,4})(\.[a-z]{2})?$/ix ? 1 : 0;
    return $st
}

sub check_valid_boxname {
    my $boxname = shift;
    return 0 if length($boxname) >= 40;
    my $bt = $boxname =~ /^[a-zA-Z][a-zA-Z0-9_]+$/i ? 1 : 0;
    $bt
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
    my $auth = $s->recoverHostFromV2(@_)->result();
    $auth;
}

sub soap_get_task {
    my $auth = $s->getTask(@_)->result();
    $auth;
}

sub soap_return_task_result {
    my $auth = $s->setTaskResult(@_)->result();
    $auth;	
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
    output $conffile,
    qq(# automatically generated file. Please don't edit
LOGIN=$login
PASS=$passwd
MACHINE=$boxname
VER=$release
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

sub setVar {
    my ($file, $val) = @_;
    my %s = getVarsFromSh($file);
    foreach my $v (@val) {
	$s{$val} = $st;
    }
    setVarsInSh($file, \%s);
}

sub read_conf() {
    my %rc = getVarsFromSh($rootconf_file); my %wc = getVarsFromSh($conf_file);
    (\%wc, \%rc)
}

sub write_conf {
    my $response = shift;
    write_wide_conf($response);
    #write_rootconf($response);
    print Dumper($response);
}

sub get_date() {
    my $date = `date --iso-8601=seconds`; # output  date/time  in ISO 8601 format. Ex: 2006-02-21T17:04:19+0100
    $date = chomp_($date);
    $date
}

sub write_wide_conf {
    my ($soap_response) = shift;
    my $date = get_date();
    output_with_perm $wideconf, 0644,
    qq(USER_EMAIL=$login
MACHINE=$boxname
COUNTRY=$country
DATE_SET=$date
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
