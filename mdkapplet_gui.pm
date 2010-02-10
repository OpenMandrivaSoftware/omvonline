package mdkapplet_gui;

################################################################################
# Mandriva Online                                                              # 
#                                                                              #
# Copyright (C) 2003-2010 Mandriva                                             #
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

use strict;
use lib qw(/usr/lib/libDrakX);
use common;

our @ISA = qw(Exporter);
our @EXPORT = qw(
                    @common
                    %local_config
                    $localdir
                    $localfile
                    $width
                    fill_n_run_portable_dialog
                    iso8601_date_to_locale
                    new_link_button
                    new_portable_dialog
                    setVar
            );


use mygtk2 qw(gtknew); #- do not import gtkadd which conflicts with ugtk2 version
use ugtk2 qw(:all);
use lib qw(/usr/lib/libDrakX/drakfirsttime);

ugtk2::add_icon_path("/usr/share/mdkonline/pixmaps/");

our $localdir = "$ENV{HOME}/.MdkOnline";
our $localfile = "$localdir/mdkonline";

#compatibility
mkdir_p($localdir) if !-d $localdir;
-e "$ENV{HOME}/.mdkonline" and system("mv", "$ENV{HOME}/.mdkonline", $localfile);

our %local_config;
read_local_config();

our $width = 500;
our @common = (
    # explicitely wrap (for 2008.1):
    line_wrap => 1,
    # workaround infamous 6 years old gnome bug #101968:
    width => $width - 50,
);

sub new_portable_dialog {
    my ($title) = @_;
    ugtk2->new($title, width => $width + 20);
}

sub fill_n_run_portable_dialog {
    my ($w, $widgets) = @_;

    # use wizard button order (for both 2008.1 & 2009.0):
    {
        local $::isWizard = 1;
        local $w->{pop_it} = 0;
        local $::isInstall = 1;
        my %children;
        if ($::isEmbedded) {
            my (@children_tight, $child);
            @children_tight = @$widgets;
            $child = pop @children_tight;
            %children = (
                children => [
                    (map { (0, $_) } @children_tight),
                    1, gtknew('Label'),
                    0, $child,
                ]
            );
        } else {
            %children = (children_tight => $widgets);
        }

        gtkadd($w->{window}, gtknew('VBox', %children));
    }

    $w->{ok}->grab_focus;
    $w->main;
}

sub new_link_button {
    my ($url, $text) = @_;
    my $link = Gtk2::LinkButton->new($url, $text);
    $link->set_uri_hook(sub {
                            my (undef, $url) = @_;
                            run_program::raw({ detach => 1, setuid => get_parent_uid() }, 'www-browser', $url);
                        });
    $link;
}

sub read_local_config() {
    %local_config = getVarsFromSh($localfile);
}

sub setVar {
    my ($var, $st) = @_;
    my %s = getVarsFromSh($localfile);
    $s{$var} = $st;
    setVarsInSh($localfile, \%s);
    read_local_config();
}

sub iso8601_date_to_locale {
    my ($date) = @_;
    return $date if $date !~ /(\d\d\d\d)-?(\d\d)-?(\d\d)/;
    require POSIX;
    POSIX::strftime("%x", 0, 0, 0, $3, $2-1, $1-1900);
}

