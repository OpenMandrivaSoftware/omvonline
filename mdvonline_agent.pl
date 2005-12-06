#!/usr/bin/perl -w
################################################################################
# mdvonline_agent                                                              # 
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

# $Id$

use strict;
use POSIX;
use lib qw(/usr/lib/libDrakX /usr/lib/libDrakX/drakfirsttime);
use common;
use mdkonline;
use Data::Dumper;

# DNS service discovery
use Discover;

# logging
use Log::Agent;
require Log::Agent::Driver::File;  # logging made to file
logconfig(
	-driver => Log::Agent::Driver::File->make(
        -prefix  => $0,
        -showpid => 1,
        -file    => 'mdvonline.log',
    ),
    #-caller => [ -display => '($sub/$line)', -postfix => 1 ],
    -priority => [ -display => '[$priority]' ],
);

# TODO set this in mdkonline.pm ?
my $conffile = '/etc/sysconfig/mdkonline';
my $service  = 'https://localhost/~romain/online3/htdocs/service';

# script starts here
mdkonline::is_running('mdvonline_agent')
	and die "mdvonline_agent already running\n";

#require_root_capability();

my %conf;
my $ret = 0;

# 1. check configuration (local) or set from dns if any
if( ( -e $conffile ) && ( -s $conffile ) ) {
	%conf = getVarsFromSh($conffile);

	if( defined $conf{MACHINE} && ! defined $conf{VERSION} ) { #|| $conf{VERSION} lt 3 ) {
		logsay "old configuration detected: trying to migrate to new scheme";
		$ret = mdkonline::upgrade_to_v3();
		if( $ret eq 1 ) { logsay "succeeded"; }
		else { logsay "failed"; }
	}
	else {
		if( defined $conf{MOBILE} && $conf{MOBILE} eq 'TRUE' ) {
			# TODO check dns service for a specific update server
			# if there is one, it may supersedes default conf update server
			# or the one provided by the Online server?
		}
		$ret = 1;
	}
}
else {
	logsay "no configuration file found";
	logsay "starting dns service discovery";
	my $sd          = new Discover;
	my $serviceinfo = $sd->search();
	if ( $serviceinfo ) {
		logsay "found service with info";
		print Dumper($serviceinfo);		
		# TODO check service certificate
		# TODO register to service
		# TODO set config file
		$ret = 0;
	}
	else {
		#print Dumper($sd);
		logsay "no service found";
		$ret = 0;
	}	
	$ret = 0;
}

if( $ret eq 1 ) {
	# 2. now check and run task
	print "checking for somethign to do.\n";
	my $task = mdkonline::soap_get_task( $conf{HOST_ID}, $conf{HOST_KEY} );
	print Dumper($task);
}

logsay "done";
$ret;