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
use Switch;
use Data::Dumper;
use Error qw(:try);

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

logsay "==================";
mdkonline::is_running('mdvonline_agent') and die "mdvonline_agent already running\n";
require_root_capability();

my %conf = mdkonline::get_configuration();
print Dumper(%conf);

! defined %conf and logwarn "no configuration set", exit 0;

logsay "checking for tasks";
print Dumper(%conf);
my $answer = mdkonline::soap_get_task( $conf{HOST_ID}, $conf{HOST_KEY} );

print Dumper($answer);

if( $answer->{code} eq 0 ) {
	if( $answer->{data}->{command} eq 'none' ) {
		logsay "nothing to do";
	}
	else {
		logsay "got something";
		my $res = mdkonline::run_and_return_task( $answer->{data} );
	}
	exit 1;
}
else {
	logwarn "something went wrong " . $answer->{message} . " (".$answer->{code}.")";
	exit 0;
}