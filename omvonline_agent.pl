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
use omvonline;
use Switch;
use Data::Dumper;
use Error qw(:try);

# DNS service discovery
use Discover;

# logging
use Log::Agent;
require Log::Agent::Driver::File;  # logging made to file
logconfig(
    '-driver' => Log::Agent::Driver::File->make(
        '-prefix'  => $0,
        '-showpid' => 1,
        '-file'    => 'omvonline.log',
    ),
    #-caller => [ -display => '($sub/$line)', -postfix => 1 ],
    '-priority' => [ '-display' => '[$priority]' ],
);

logsay "==================";
omvonline::is_running('omvonline_agent') and die "omvonline_agent already running\n";
require_root_capability();

my %conf = omvonline::get_configuration();
print Dumper(%conf);

! defined %conf and logwarn "no configuration set", exit 0;

logsay "checking for tasks";
print Dumper(%conf);
my $answer = omvonline::soap_get_task($conf{HOST_ID}, $conf{HOST_KEY});

print Dumper($answer);

if ($answer->{code} == 0) {
	if ($answer->{data}{command} eq 'none') {
		logsay "nothing to do";
	}
	else {
		logsay "got something";
		omvonline::run_and_return_task($answer->{data});
	}
	exit 1;
}
else {
	logwarn "something went wrong " . $answer->{message} . " (" . $answer->{code} . ")";
	exit 0;
}
