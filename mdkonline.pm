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
use Switch;
use Log::Agent; # use settings from main file
use Error qw(:try);

#For debugging
use Data::Dumper;

my $release_file = find { -f $_ } '/etc/mandriva-release', '/etc/mandrakelinux-release', '/etc/mandrake-release', '/etc/redhat-release';
my $uri          = 'https://localhost/~romain/online3/htdocs/soap';
#my $uri          = 'https://online.mandriva.com/soap';
my $serviceProxy = $uri;
my $onlineProxy  = $uri;

my $useragent = set_ua('mdkonline');

sub is_proxy () {
    return 1 if defined $ENV{http_proxy};
}

my $s = is_proxy() ? SOAP::Lite->uri($uri)->proxy($serviceProxy, proxy => [ 'http' => $ENV{http_proxy} ], agent => $useragent) : SOAP::Lite->uri($uri)->proxy($serviceProxy, agent => $useragent);

#
sub get_configuration {
	my $in = shift;
	my $config_file = '/etc/sysconfig/mdkonline';
	my %conf;
	my $ret;

	logsay "checking configuration";	
	try {
		# check local config file	
		if( ! ( -e $config_file ) || ! ( -s $config_file ) ) {
			logsay "checking dns service";
			%conf = get_conf_from_dns();
			print "from dns:\n",Dumper(%conf),"\n";
			if( %conf ) {
				
			}
			else { throw( ) }
			if( %conf eq undef ) {
				logwarn "found none";
			} else {
				logsay "found one";
			}
		}
		else {
			# found one
			logsay "found $config_file";
			%conf = getVarsFromSh($config_file);
			if( defined $conf{MACHINE} && ! defined $conf{VERSION} ) {
				# old (v2) config
				logsay "old (v2) conf found; trying to upgrade to v3";
				$ret = upgrade_to_v3();
				print "\n", $ret, "\n";
				if( $ret eq 1 ) {
					logsay "succeeded; reloading configuration";
					# reload config
					%conf = getVarsFromSh($config_file);
				}
				else {
					logsay "failed. stop.";
					# TODO what do we do now? email warning? support? forget it?
					%conf = undef;
				}
			}
		}
	}
	catch Error with {
		my $ex = shift;
		print Dumper($ex);
	}
	finally {
		
	};
	
	# now, a valid working config file is loaded
	if( defined $conf{MOBILE} && $conf{MOBILE} eq 'TRUE' ) {
		logsay "checking for mobile options";
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
	
	defined $params->{customer_id} and $current{CUSTOMER_ID} = $params->{customer_id};
	defined $params->{host_id} and $current{HOST_ID} = $params->{host_id};
	defined $params->{host_key} and $current{HOST_KEY} = $params->{host_key};
	defined $params->{host_name} and $current{HOST_NAME} = $params->{host_name};
	! defined $current{VERSION} and $current{VERSION} = 3;
	defined $params->{country} and $current{COUNTRY} = $params->{country};
	defined $params->{mobile} and $current{MOBILE} = $params->{mobile};
	defined $params->{auto} and $current{AUTO} = $params->{auto};
	$current{DATE_SET} = chomp_(`LC_ALL=C date`);

	print Dumper(%current);
	print setVarsInSh( '/etc/sysconfig/mdkonline', %current );
	%current;
};

#
sub upgrade_to_v3 {
	my $oldconffile = '/root/.MdkOnline/mdkupdate';
	if( ( -e $oldconffile ) && ( -s $oldconffile ) ) {
		my %old = getVarsFromSh('/root/.MdkOnline/mdkupdate');
		if( $old{LOGIN} ne '' && $old{PASS} ne '' && $old{MACHINE} ne '' ) {
			my $res = mdkonline::soap_recover_service($old{LOGIN},'{md5}'.$old{PASS},$old{MACHINE},$old{COUNTRY});
			if( $res->{code} eq '0' || $res->{code} == 0 ) {
				#logsay "succeeded to register anew to service; configuring local host.";
				my $cd = $res->{data};
				$cd->{auto}    = 'FALSE';
				$cd->{mobile}  = 'FALSE';
				$cd->{country} = '';
				$cd->{service} = 'https://online.mandriva.com/service';
				
				mdkonline::save_config( $res->{data} );
				return 1;
			}
			else {
				$res->{code} eq '1' and logwarn "this host may be already registered";
				logwarn "failed to recover service; answer was: " . $res->{message} . "(" . $res->{code} . ")";	
			}
		}
		else {
			# missing info in config file; invalid;
			#logwarn "failed to recover service; config file is missing some info.";
		}
	}
	else {
		# no config file found;
		#logwarn "no config file has been found (" . $oldconffile . ")";
	}
	return undef;
};

sub register_from_dns {
	my $dnsconf = shift;

	my $user = $dnsconf->{user}->{name} || '';
	my $pass = $dnsconf->{user}->{pass} || '';
	my $hostname = chomp_(`hostname`);
	my $hostinfo = '';
	my $country = ''; # FIXME
	# TODO change SOAP proxy to the one indicated at $dnsconf->{service} before
	# TODO wrap all soap calls into an object so we can update the proxy on the fly?
	my $res = mdkonline::soap_register_host( $user, $pass, $hostname, $hostinfo, $country );
	if( $res->{code} eq 0 ) {
		$res->{data}->{service} = $dnsconf->{service};
		return mdkonline::save_config( $res->{data} );
	}
	return undef;	
}

sub get_conf_from_dns {
	my $sd   = new Discover;
	my $info = $sd->search();
	my $ret;
	if( $info ) {
		logsay "found service";
		if( defined $info->{user}->{name} && defined $info->{user}->{pass}
			&& $info->{user}->{name} ne '' && $info->{user}->{pass} ne '' ) {
			print Dumper($info);
			# TODO check service certificate
			$ret = mdkonline::register_from_dns( $info );
			if( $ret ) {
				return $ret;
			}
			else {
				logsay "failed to register to dns declared service";
			}
		}
		else {
			logsay "does not permit automatic registration (no user info)";
		}
	}
	else {
		logsay "no service info found";	
	}
	return;
}

#
sub run_and_return_task {
	my $task = shift;
	my $ret;
	
	if( $task->{command} ne 'none' ) {
#		switch( $task->{command} ) {
#			case 'update' {
#				#$task->{mirror}
#				#$task->{packages}
#			}
#			case 'upload_config' {
#				#
#			}
#			case 'set_params' {
#				#$task->{params}
#			}
#			case 'none' {
#				logsay "nothing to do";
#			}
#			else {
#				logwarn "unknown task " . $task->{command};	
#			}	
#		}
#		# TODO soap_return_task_result();
	}
	else {
		$ret = 1;	
	}
	$ret;
};


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
    my ($release) = cat_($release_file) =~ /release\s+(\S+)/;
    ($release)
}

sub set_ua {
    my $package_name = shift;
    my $qualified_name = chomp_(`rpm -q $package_name`);
    $qualified_name
}

sub get_distro_type {
    my $release = cat_($release_file);
    my ($arch) = $release =~ /\s+for\s+(\w+)/;
    my ($name) = $release =~ /(corporate|mnf)/i;
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
		  authenticate => sub { eval { $response = soap_authenticate_user(@info) }; }
		 };
    $action->{$type}->();
    $ret = check_server_response($response, $hreturn);
    $ret;
}

sub check_server_response {
    my ($response, $h) = @_;
    my $code = $response->{code} || '99';
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
