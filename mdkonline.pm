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

use lib qw(/usr/lib/libDrakX);
use common;
use ugtk2;

our @ISA = qw(Exporter);
our @EXPORT = qw(fork_exec get_banner get_stale_upgrade_filename);

our $version = 2.67;

use log;

my $release_file = find { -f $_ } '/etc/mandriva-release', '/etc/mandrakelinux-release', '/etc/mandrake-release', '/etc/redhat-release';


sub get_stale_upgrade_filename() {
    '/var/lib/urpmi/stale_upgrade_in_progress';
}

sub get_release() {
    my ($r) = cat_($release_file) =~ /release\s+(\S+)/;
    ($r);
}

sub clean_confdir() {
    my $confdir = '/root/.MdkOnline';
    system "/bin/rm", "-f", "$confdir/*log.bz2", "$confdir/*log.bz2.uue", "$confdir/*.dif $confdir/rpm_qa_installed_before", "$confdir/rpm_qa_installed_after";
}


sub fork_exec {
    run_program::raw({ detach => 1 }, @_);
}

sub get_banner {
    my ($o_title) = @_;
    Gtk2::Banner->new(
        (find { -e $_ } 
           qw(/usr/share/mcc/themes/default/rpmdrake-mdk.png /usr/share/icons/large/mdkonline.png)),
        $o_title || N("Distribution Upgrade")
    );
}

sub is_running {
    my ($name) = @_;
    my $found;
    foreach (`ps -o '%P %p %c' -u $ENV{USER}`) {
        my ($ppid, $pid, $n) = /^\s*(\d+)\s+(\d+)\s+(.*)/;
        if ($ppid != 1 && $pid != $$ && $n eq $name) {
            $found = $pid;
            last;
        }
    }
    $found;
}

1;
