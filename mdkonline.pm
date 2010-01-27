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
our @EXPORT = qw(find_current_distro
                 fork_exec
                 get_banner
                 get_distro_list_
                 get_distro_list
                 get_from
                 get_product_id
                 get_release
                 get_stale_upgrade_filename
                 get_urpmi_options
                 is_it_2008_0
                 is_enterprise_media_supported
                 is_restricted_media_supported
                 translate_product
                 xml2perl
                 %config
                 $product_id
                 $root);

our (%config, $product_id, $root);
our $version = 2.67;

use log;

my $release_file = find { -f $_ } '/etc/mandriva-release', '/etc/mandrakelinux-release', '/etc/mandrake-release', '/etc/redhat-release';


sub get_stale_upgrade_filename() {
    '/var/lib/urpmi/stale_upgrade_in_progress';
}

sub get_product_id() {
    $product_id = common::parse_LDAP_namespace_structure(cat_("$root/etc/product.id"));
}

sub get_release() {
    my ($r) = cat_($release_file) =~ /release\s+(\S+)/;
    ($r);
}

sub is_it_2008_0() {
  $product_id->{version} eq '2008.0';
}

sub is_enterprise_media_supported() {
    return if is_it_2008_0();
    to_bool($product_id->{type} eq 'Enterprise' && $product_id->{product} eq 'Server');
}

sub is_restricted_media_supported() {
    return if is_it_2008_0();
    to_bool($product_id->{product} =~ /powerpack/i);
}

sub find_current_distro {
    find { $_->{version} eq $product_id->{version} } @_;
}

sub get_distro_list_() {
    #- contact the following URL to retrieve the list of released distributions.
    my $type = lc($product_id->{type}); $type =~ s/\s//g;
    my $extra_path = $::testing || uc($config{TEST_DISTRO_UPGRADE}) eq 'YES' ? 'testing-' : '';
    my $list = 
      join('&',
           "https://api.mandriva.com/distributions/$extra_path$type.$product_id->{arch}.list?product=$product_id->{product}",
           "version=$product_id->{version}",
           "mdkonline_version=$mdkonline::version",
       );
    log::explanations("trying distributions list from $list");

    eval {
        my $urpm = Rpmdrake::open_db::fast_open_urpmi_db();

        # prevent SIGCHILD handler's waitpid to interfere with urpmi waiting
        # for curl exit code, which broke downloads:
        local $SIG{CHLD} = 'DEFAULT';

        # old API:
        if (member($product_id->{version}, qw(2007.1 2008.0 2008.1))) {
            require mdkapplet_urpm;
            mdkapplet_urpm::ensure_valid_cachedir($urpm);
            mdkapplet_urpm::get_content($urpm, $list);
        } else {
            urpm::ensure_valid_cachedir($urpm);
            urpm::download::get_content($urpm, $list);
        }
    };
}

sub get_distro_list() {
    return if $product_id->{product} =~ /Flash/;

    my @lines = get_distro_list_();

    if (my $err = $@) {
        log::explanations("failed to download distribution list:\n$err");
        return; # not a fatal error
    }
    
    if (!@lines) {
        log::explanations("empty distribution list");
        return;
    }

    map { common::parse_LDAP_namespace_structure(chomp_($_)) } @lines;
}


sub clean_confdir() {
    my $confdir = '/root/.MdkOnline';
    system "/bin/rm", "-f", "$confdir/*log.bz2", "$confdir/*log.bz2.uue", "$confdir/*.dif $confdir/rpm_qa_installed_before", "$confdir/rpm_qa_installed_after";
}


sub fork_exec {
    run_program::raw({ detach => 1 }, @_);
}

sub translate_product() {
    my %strings = (
        Flash => N("Mandriva Flash"),
        Free => N("Mandriva Free"),
        Mini => N("Mandriva Mini"),
        One => N("Mandriva One"),
        PowerPack => N("Mandriva PowerPack"),
        Server => N("Mandriva Enterprise Server"),
    );
    my $product = $product_id->{product};
    $strings{$product} || $product;
}

sub get_banner_icon() {
    find { -e $_ } 
      qw(/usr/share/mcc/themes/default/rpmdrake-mdk.png /usr/share/icons/large/mdkonline.png);
}

sub get_banner {
    my ($o_title) = @_;
    Gtk2::Banner->new(get_banner_icon(), $o_title || N("Distribution Upgrade"));
}

sub get_urpmi_options() {
    ({ sensitive_arguments => 1 }, 'urpmi.addmedia', '--xml-info', 'always');
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


sub get_from {
    my ($link, $header) = @_;
    
    my $ua = LWP::UserAgent->new;
    $ua->agent(sprintf('mdkapplet (mdkonline-%s; distribution: %s)',
                       $mdkonline::version, $version));
    $ua->env_proxy;

    my $response = $ua->post($link, $header);
    $response;
}

# callers need to require XML::Simple
sub xml2perl {
    my ($res) = @_;
    my $ref = eval { XML::Simple->new->XMLin($res->{_content}) };
    if (my $err = $@) {
        warn ">> XML error: $err\n";
        $ref = {
            code => 1,
            message => $err,
        };
    }
    $ref;
}


1;
