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
use feature 'state';
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

our @EXPORT_OK = qw(
    $powerpack_ad
    run_ask_credentials_dialog
    run_no_rights_dialog
    open_ask_powerpack_dialog
);

use mygtk2 qw(gtknew); #- do not import gtkadd which conflicts with ugtk2 version
use ugtk2 qw(:all);
use mdkonline qw();	# you don't want to polute the namespace
use interactive;
use interactive::gtk;
use lib qw(/usr/lib/libDrakX/drakfirsttime);

ugtk2::add_icon_path("/usr/share/mdkonline/pixmaps/");

our $localdir = "$ENV{HOME}/.MdkOnline";
our $localfile = "$localdir/mdkonline";

#compatibility
mkdir_p($localdir) if !-d $localdir;
-e "$ENV{HOME}/.mdkonline" and system("mv", "$ENV{HOME}/.mdkonline", $localfile);

interactive::gtk::add_padding(Gtk2::Label->new);

our %local_config;
read_local_config();

our $width = 500;
our @common = (
    # explicitely wrap (for 2008.1):
    line_wrap => 1,
    # workaround infamous 6 years old gnome bug #101968:
    width => $width - 50,
);

# List of widgets advertising Powerpack
our $powerpack_ad = [
    gtknew('Label_Left',
           text => N("Mandriva Powerpack brings you the best of Linux experience for desktop: stability and efficiency of open source solutions together with exclusive softwares and Mandriva official support."),
           @common),
    gtknew('HButtonBox',
           layout => 'center',
           children_tight => [
               new_link_button(
                   'http://www2.mandriva.com/linux/features/',
                   N("Mandriva Linux Features")
               )
           ]),
    gtknew('Label_Left',
           text => 'You can order now access for Powerpack',
    ),
    gtknew('HButtonBox',
           layout => 'center',
           children_tight => [
               new_link_button(
                   'http://store.mandriva.com/pwp/',
                   N("Online subscription")
               )
           ]),
];

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

# %options keys:
#
# 'top_extra': reference to a list of widgets to shown on top of dialog.
#
sub run_ask_credentials_dialog {
    my ($title, $description, $callback, %options) = @_;

    my $w = new_portable_dialog($title);
    my $password_text;
    state $email_text;
    my $password_w = gtknew('Entry');
    my $email_w = gtknew('Entry', text => $email_text);
    my $ok_clicked;

    $password_w->set_visibility(0);

    $w->{ok_clicked} = sub { 
	$password_text = $password_w->get_text;
	$email_text = $email_w->get_text;
	$ok_clicked = 1;
	Gtk2->main_quit;
    };

    my @widgets = (
	if_(!$::isEmbedded, mdkonline::get_banner($title)),
        if_($options{top_extra},
            @{ $options{top_extra} },
            gtknew('HSeparator'),
        ),
	gtknew('Label_Left',
	       text => $description,
	       @common),
	gtknew('HButtonBox',
	       layout => 'start',
	       children_tight => [
		   interactive::gtk::add_padding(
		       new_link_button(
			   'https://my.mandriva.com/info',
			   N("More information on your user account")
		       )
		   )
	       ]),
	gtknew('Table',
	       col_spacings => 5,
	       row_spacings => 5,
	       children => [ [ N("Your email"), $email_w ],
			     [ N("Your password"), $password_w ] ]),
	gtknew('HButtonBox',
	       layout => 'start',
	       children_tight => [
		   interactive::gtk::add_padding(
		       new_link_button(
			   'https://my.mandriva.com/reset/password/',
			   N("Forgotten password")
		       )
		   )
	       ]),
	ugtk2::create_okcancel($w, N("Next"), N("Cancel")),
	);

    fill_n_run_portable_dialog($w, \@widgets);

    if ($ok_clicked) {
	$ok_clicked = 0;
	if ($email_text && $password_text) {
	    $callback->($email_text, $password_text);
	}
	else {
	    interactive->vnew->ask_warn(
		N("Error"), 
		N("Password and email cannot be empty.")
		);
	    goto &run_ask_credentials_dialog;
	}
    }
}

sub run_no_rights_dialog {
    my ($title, $info, $info_url) = @_;
    my $w = new_portable_dialog($title);
    my @widgets = (
	mdkonline::get_banner($title),
	gtknew('Label_Left',
	       text => $info,
	       @mdkapplet_gui::common),
	gtknew('HButtonBox',
	       layout => 'start',
	       children_tight => [
		   interactive::gtk::add_padding(
		       new_link_button($info_url, N("More Information"))
		   )
	       ]),
	create_okcancel($w, N("Close"), undef)
	);
    fill_n_run_portable_dialog($w, \@widgets);
}

# Returns a string of user's choice: 'powerpack' or 'free'.
sub open_ask_powerpack_dialog {
    my ($current_product, $new_version) = @_;

    # Setup powerpack offering radio buttons...

    my @radio_widgets;
    my $rbutton;
    # pwp/flash users will be offered powerpack by default
    my $want_powerpack = $current_product =~ /powerpack|flash/i;
    for my $product ($want_powerpack
                         ? ('powerpack', 'free') : ('free', 'powerpack')) {
        my $info = mdkonline::get_product_info($product);
        $rbutton 
            = Gtk2::RadioButton->new_with_label($rbutton
                                                    ? $rbutton->get_group
                                                    : undef,
                                                $info->{name});
        $rbutton->signal_connect('toggled', 
                                 sub {
                                     my ($button, $is_pwp) = @_;
                                     $want_powerpack = $is_pwp 
                                         unless not $button->get_active();
                                 }, 
                                 $product eq 'powerpack');
        push @radio_widgets, [ $rbutton, $info->{description} ];
    }

    # Setup dialog widgets...

    my $title = N("Choose your upgrade version");
    my $w = new_portable_dialog($title);
    my @widgets 
        = (mdkonline::get_banner($current_product =~ /powerpack/i
                                     ? N("Your Powerpack access has ended")
                                     : $title),
           gtknew('Label_Left',
                  text => N("%s is now available, you can upgrade to:", 
                            $new_version),
                  @common),
           gtknew('Table', children => \@radio_widgets, row_spacings => 10),
           ugtk2::create_okcancel($w, N("Next"), N("Cancel")),
        );
    
    fill_n_run_portable_dialog($w, \@widgets) or return undef;
    return $want_powerpack;
}
