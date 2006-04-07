#!/usr/bin/perl
################################################################################
# migrate-mdvonline-applet.pl                                                  # 
#                                                                              #
# Copyright (C) 2006 Mandriva                                                  #
#                                                                              #
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

use lib qw(/usr/lib/libDrakX);
use standalone; # for explanations

my $run_file = '/var/run/mdkapplet';

my $mode = $ARGV[0];

if (!-e $run_file) {
    # create the stamp file is needed:
    open(my $_tmp, '>>', $run_file);
} else {
    # exit if we're asked to restart the applets twice in less than 30 seconds
    # (eg the trigger script is run by both removed and newly installed packages,
    # which can lead to applet crash on SIGHUP because of race condition):
    my $mtime = (stat($run_file))[9];
    log::explanations("not restarting the applet (too many restart in a while)");
    exit(0) if time() - $mtime < 30;
}

if ($mode eq 'new') {
    system('killall', '-HUP', 'mdkapplet');
} else {
    #my @lines = `ps -o '$p $u %c'`;
    my @lines = `ps -eo pid,user,cmd`;
    
    # we do not live process ps output in order not to account both old applets and newly started ones:
    foreach (@lines) {
        my ($pid, $user, $cmd) = /^\s*(\d+)\s*(\S*)\s*(.*)$/;
        # do not match su running mdkapplet:
        next if $cmd !~ /perl.*mdkapplet/;
        log::explanations(qq(killing "$cmd" (pid=$pid)));
        kill 15, $pid;
        my $pid2 = fork();
        if (defined $pid2) {
            !$pid2 and do { exec('su', $user, '-c', 'mdkapplet --auto-update') or do { require POSIX; POSIX::_exit() } };
            log::explanations("restarting applet (pid=$pid2)");
        } else {
            log::explanations(qq(failed to fork Mandriva Online applet for user "$user"));
        }
    }
}

my $atime = time();
utime(($atime) x 2, $run_file);
