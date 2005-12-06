package Discover; # $Id$

################################################################################
# Part of Mandriva Online                                                      #
# Online service discovery library:                                            #
# - autodetects nameservers and domains,                                       #
# - and checks for DNS-declared Online service,                                #
#                                                                              #
# Check http://www.dns-sd.org/                                                 #
#                                                                              #
# Copyright (C) 2005 Mandriva                                                  #
#                                                                              #
# Romain d'Alverny <rdalverny at mandriva dot com>                             #
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

use strict;
use Net::DNS;
use Data::Dumper;
use MDK::Common;
use Config::Auto; # CPAN Module. Seems not to be part of Mandriva packages yet.
use Switch;

use Log::Agent; # use settings from main file

my $VERSION = '0.01';

#
sub new
{
	my $self = {};
	bless $self, "Discover";
	logsay "DNS Service Discovery module $VERSION";
	return $self;
}

#
sub init
{
	my $this = shift;
	$this->{domainname} = '';
	$this->{zone}       = '';
	$this->{service}    = '';
	$this->{nameserver} = '';
	$this->{instance}   = '';
};

#
sub trim {
	my $s = shift;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	return $s;
};

#
sub commify_series {
    (@_ == 0) ? '' :
    (@_ == 1) ? $_[0] :
    (@_ == 2) ? join(" and ", @_) :
                join(", ", @_[0 .. ($#_-1)], "and $_[-1]");
};

#
sub search {
	my $this = shift;
	
	logsay "searching for a locally declared Mandriva Online service";

	my $resolv      = Config::Auto::parse('/etc/resolv.conf');
	my $servicetype = '_mdvonline._http._tcp.bonjour.';
	my @domains     = ();
	my @services    = ();
	
	if( ! defined $resolv ) {
		logerr "No config found from /etc/resolv.conf .";
		return 0;	
	}
	
	if( defined $resolv->{domain} ) {
		@domains = $resolv->{domain};
	}
	if( defined $resolv->{search} ) {
		push( @domains, @{$resolv->{search}} );
	}
	
	@domains = uniq(@domains);
	for my $domain ( @domains ) {
		push( @services, $servicetype . $domain );
	}
	logsay "found domains: " . commify_series(@domains);
	logsay "found nameservers: " . commify_series(@{$resolv->{nameserver}});

	# for dev.
	@{$resolv->{nameserver}} = qw(localhost);
	
	# will try each nameserver listed
	for my $ns ( @{$resolv->{nameserver}} ) {
		# for each possible service/domain
		for my $serv ( @services ) {
			logsay "trying ns $ns, service $serv";
			my $ret = $this->find_service( $ns, $serv );
			if( $ret ) {
				logsay "search is over: a service has been found.";
				return $ret;
			}
		}
	}
	logwarn "no dns-declared service found";
	return 0;
};
 
# NOTE. here it is suppposed that for a given Service instance (PTR),
# there is only _one_ SRV record and _one_ TXT record matches.
# If there are more, no particular behaviour is expected as for now.
sub find_service {
	my ($this, $nameserver, $service) = @_;
	my $return;

	# lower the values to make it faster to give up
	my $retry = 2;   # default is 120
	my $retrans = 2; # default is 5
	logsay "retry rate is set to $retry; retrans rate is set to $retrans";
	my $res = Net::DNS::Resolver->new(
					retry => $retry,
					retrans => $retrans,
					#debug => 1
	);
	
	# TODO make sure the nameserver answers, or set a timeout.
	$res->nameservers( $nameserver );

	# 1. search for any PTR record matching the service name	
	logsay "ns $nameserver: PTR $service ?";
	my $query = $res->query( $service, 'PTR' );
	my $instanceName;
	if( $query ) {
		# TODO better parsing of the struct
		my $rr = $query->{answer}[0];
		if( ! defined $rr ) {
			logerr "not expected format found in PTR record.";
			return 0;	
		}
		$instanceName = $rr->ptrdname;
		$instanceName =~ s/\\032/ /g;
		logsay "found '$instanceName'";
		$this->{serviceInstanceName} = $instanceName;
	}
	else {
		logwarn "no PTR record found.";
		logwarn $res->errorstring;
		return 0;	
	}
	
	# 2. for each service instance found, look up for SRV/TXT records.
	logsay "ns $nameserver: SRV '$instanceName' ?";
	$query = $res->query( $instanceName, 'SRV' );
	if( $query ) {
		my $rr = $query->{answer}[0];
		logsay "yes: " . $rr->target . ":" . $rr->port;
		$this->{server} = { priority => $rr->priority, weight => $rr->weight,
							port => $rr->port, host => $rr->target };
		$return->{server} = $this->{server};
	}
	else {
		logwarn "no matching SRV record found.";
		logwarn $res->errorstring;
		return 0;
	}
	
	logsay "ns $nameserver: TXT '$instanceName' ?";
	$query = $res->query( $instanceName, 'TXT' );
	if( $query ) {
		my $rr = $query->{answer}[0];
		logsay "yes: " . join(', ', $rr->char_str_list() );
		$return->{config} = $this->parse_txt_config( $rr->char_str_list() );
		if( ! defined $return->{config} ) {
			logwarn "But no config found.";
			return 0;	
		}
	}
	else {
		logwarn "No matching TXT record found.";
		logwarn $res->errorstring;
		return 0;
	}
	return $return;
};

# translate the txt records into a properly formatted hash.
sub parse_txt_config {
	my ($this, @config) = @_;
	my $retconfig;
	
	for my $line ( @config ) {
		my @line = split('=', $line);
		my $key = $line[0];
		shift(@line);
		my $value = join('=', @line);
		#print "key: $key\tvalue: $value\n";	
		switch( $key ) {
			case 'txtvers' { $retconfig->{txtvers} = $value; }
			case 'conf' {
				my @co = split(',', $value);
				$retconfig->{conf} = { 'name' => $co[0], 'time' => $co[1]	};
			}
			case 'update' {
				my @up = split(',', $value);
				$retconfig->{update} = { 'type' => $up[0], 'path' => $up[1] };
			}
			case 'service' { $retconfig->{service} = $value; }
			case 'user' { $retconfig->{user} = $value; }
			case 'pass' { $retconfig->{pass} = $value; }
			case 'auto' { $retconfig->{auto} = 1; }
			else {}
		}
	}
	$this->{config} = $retconfig;
	return $retconfig;
};

1;