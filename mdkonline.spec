%define version 2.1
%define name mdkonline
%define release %mkrel 1

Summary:	Mandriva Online Update Tool  
Name:		%{name}
Version:	%{version}
Release: 	%{release}
Source0:	%{name}-%{version}.tar.bz2
URL:		http://www.mandrivaonline.com
License:	GPL
Group:		System/Configuration/Other
Requires:  	drakxtools-newt, perl-Gtk2-TrayIcon >= 0.03-3mdk, perl-Crypt-SSLeay >= 0.51-2mdk
# we need wget for authenticated media:
Requires: wget
# for gurpmi.addmedia:
Requires: rpmdrake > 2.20-3.1.20060mdk
# for good gurpmi:
Requires: urpmi > 4.7.15-1.2.20060mdk
Provides:   %{name}-backend
Obsoletes:  %{name}-backend
Requires:	hwdb-clients >= 0.15.1-1mdk
BuildRequires: 	gettext, perl-MDK-Common-devel
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch: 	noarch

%description
The Mandriva Online tool is designed for registered users 
who want to upload their configuration (packages, hardware infos). 
This allows them to be kept informed about security updates, 
hardware support/enhancements and other high value services.
The package include :
* Wizard for users registration and configuration uploads, 
* Update daemon which allows you to install security updates 
  automatically,
* A KDE/Gnome/IceWM compliant applet for security updates notification
  and installation. 

%prep
%setup -q

%build
perl -pi -e 's!my \$ver = 1;!my \$ver = '"'%version-%release'"';!' mdkapplet

%install
rm -rf $RPM_BUILD_ROOT
make PREFIX=$RPM_BUILD_ROOT install 

#symbolic link to drakonline and older path
mkdir -p %buildroot%_prefix/X11R6/bin/
#ln -sf %_sbindir/mdkonline %buildroot%_sbindir/drakclub
ln -sf %_sbindir/mdkonline %buildroot%_sbindir/drakonline
ln -sf %_sbindir/mdkonline %buildroot%_prefix/X11R6/bin/mdkonline

mkdir -p $RPM_BUILD_ROOT%_sysconfdir/X11/xinit.d
cat > $RPM_BUILD_ROOT%_sysconfdir/X11/xinit.d/mdkapplet <<EOF
#!/bin/sh
DESKTOP=\$1
case \$DESKTOP in
   KDE|GNOME|IceWM) exec /usr/bin/mdkapplet;;
esac
EOF

chmod +x $RPM_BUILD_ROOT%_sysconfdir/X11/xinit.d/mdkapplet

#install lang
%{find_lang} %{name}

#install menu
mkdir -p $RPM_BUILD_ROOT%{_menudir}
cat > %{buildroot}%{_menudir}/%{name} <<EOF
?package(%{name}): needs="x11" command="%{_sbindir}/%{name}" section="System" icon="mdkonline.png" title="Mandriva Online" longtitle="Wizard for update service subscription" xdg="true"
?package(%{name}): command="%{_sbindir}/mdkupdate --bundle" needs="x11" kde_opt="InitialPreference=15" section="Configuration/Other" mimetypes="application/x-mdv-exec" title="Mandriva Online Bundle" longtitle="Mandriva Linux bundle handler" xdg="true"
EOF

mkdir -p $RPM_BUILD_ROOT%{_datadir}/applications
cat > $RPM_BUILD_ROOT%{_datadir}/applications/mandriva-mdvonline.desktop <<EOF
[Desktop Entry]
Name=Mandriva Online
Comment=Wizard for update service subscription
Exec=%{_sbindir}/%{name}
Icon=mdkonline.png
Type=Application
StartupNotify=true
Categories=X-MandrivaLinux-System-Configuration-Networking;Settings;Network;
EOF

cat > $RPM_BUILD_ROOT%{_datadir}/applications/mandriva-mdvonline.desktop <<EOF
[Desktop Entry]
Name=Mandriva Online Bundle
Comment=Mandriva Linux bundle handler
Exec=%{_sbindir}/mdkupdate --bundle
Icon=mdkonline.png
MimeType=application/x-mdv-exec
Type=Application
StartupNotify=true
Categories=X-MandrivaLinux-System-Configuration-Other;Settings;
EOF


%post
/usr/bin/update-mime-database /usr/share/mime >/dev/null
%{update_menus}
[ -x %{_bindir}/update-mime-database ] && update-mime-database /usr/share/mime >/dev/null

if [ -r /etc/cron.daily/mdkupdate ]; then
  perl -p -i -e 's!/usr/bin/mdkupdate!/usr/sbin/mdkupdate!' /etc/cron.daily/mdkupdate
fi

%triggerun -- mdkonline < 2.0-11mdk
[[ $2 ]] || exit 0
%{_sbindir}/migrate-mdvonline-applet.pl old
:

%triggerin -- mdkonline > 2.0-10mdk
[[ $2 ]] || exit 0
%{_sbindir}/migrate-mdvonline-applet.pl new
:

%postun
%{clean_menus}
if [ $1 = 0 ]; then
		[ -x %{_bindir}/update-mime-database ] && update-mime-database /usr/share/mime >/dev/null
fi

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}.lang
%defattr(-,root,root)
%doc COPYING ChangeLog
%{_sbindir}/mdkupdate
%{_sbindir}/mdkonline
%{_sbindir}/migrate-mdvonline-applet.pl
%{_sbindir}/drakonline
%{_bindir}/*
%{_prefix}/X11R6/bin/*
%dir %{_prefix}/lib/libDrakX/drakfirsttime
%{_prefix}/lib/libDrakX/drakfirsttime/*.pm
%{_menudir}/%{name}
%{_datadir}/applications/mandriva-*.desktop
%{_miconsdir}/*.png
%{_iconsdir}/*.png
%{_liconsdir}/*.png
%_datadir/mime/packages/*
%_datadir/applications/
%_datadir/mimelnk/applications/
%{_datadir}/%{name}/pixmaps/*.png
%_sysconfdir/X11/xinit.d/mdkapplet

##################################################################
#
#
# !!!!!!!! WARNING => THIS HAS TO BE EDITED IN THE CVS !!!!!!!!!!!
#
#
##################################################################
# get the source from our cvs repository (see
# http://www.mandrivalinux.com/en/cvs.php3)

%changelog
* Thu Aug 31 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.1-1mdv2007.0
- XDG menu
- translation snapshot

* Thu Apr 13 2006 Warly <warly@mandrakesoft.com> 2.0-15mdk
- Include server error message when requiring the bundle

* Tue Apr 11 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-14mdk
- applet: do not flood logs when config file is not there
- mdkupdate:
  o ensure we only display one window while installing a bundle
  o fortify error checking
  o remove the wait message prior to displaying an error message

* Mon Apr 10 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-13mdk
- fix restarting old applets

* Fri Apr  7 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-12mdk
- applet:
  o do not flash the main window when opening the contextual menu of
    the icon
  o uniconize the main window when clicking again on the systray icon

* Thu Apr  6 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-11mdk
- applet:
  o "about..." now popups an about dialog
  o raise the window when it's already displayed and the user clicks
    again on the systray icon (#21906)
  o restart it on update

* Wed Apr 05 2006 Warly <warly@mandrakesoft.com> 2.0-10mdk
- Correctly keep the POST line from the bundle file (for auto-select preset)

* Tue Apr  4 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-9mdk
- mdkapplet: fix crash when run as non root

* Tue Apr  4 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-8mdk
- mkdupdate: fix auto registering host when installing a bundle

* Mon Apr  3 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-7mdk
- applet: fix displaying hostname
- mdkupdate: autoregister the host instead of running the mdkonline
  wizard when installing a bundle

* Mon Apr  3 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-6mdk
- mdkonline: add a usage message
- mdkupdate: make legacy updates work
- applet:
  o set busy cursor while running mdkupdate
  o wrap status message

* Thu Mar 30 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-5mdk
- show the "Mandriva Online" entry earlier in the "server/" root menu
  branch)
- applet:
  o more understandable message and set busy cursor while querying the
    server
  o wrap text
- fix running wizard on mdv2006
- fix crash while registering the host

* Wed Mar 29 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-4mdk
- log what's done in /var/log/explanations
- mdkapplet:
  o switch to new SOAP interface
  o use new server to check for updates
- mdkonline:
  o center subdialogs on main window
  o display error messages in various places
  o fix account creation wizard
  o fix running wizards on cooker
  o fix some GUI oddities
- mdkupdate:
  o display error messages in various places
  o display the "preparing" popup earlier so that the user had some
    feedback once he has clicked on al bundle on the web page
  o use new server API for getting updates

* Thu Mar 16 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-3mdk
- log what is done
- add MIME support for KDE3 (it does not support the XDG mime trees
  and still relies on its own mime placement) (helio)

* Thu Mar 09 2006 Warly <warly@mandrakesoft.com> 2.0-2mdk
- Change Soap format (Thierry Vignaud)

* Thu Mar  2 2006 Thierry Vignaud <tvignaud@mandriva.com> 2.0-1mdk
- mimetype association between bundle and mdkupdate (fcrozat)
- Mandriva Online V3 (daouda & me)
- extra package installation and update capabilities (daouda, me)
- clean up (daouda, me)
- wizards works on both cooker and MDV2006
- misc bug fixes

* Fri Dec  9 2005 Daouda LO <daouda@mandriva.com> 1.4-0.1mdk
- display updates to install even if server is out of sync
- fully SOAP enabled 

* Wed Nov 16 2005 Daouda LO <daouda@mandriva.com> 1.3-7mdk
- update TODO
- Change fuzzy menu title

* Fri Oct 21 2005 Daouda LO <daouda@mandriva.com> 1.3-6mdk
- add trailing '/' for online help

* Tue Oct 18 2005 Daouda LO <daouda@mandriva.com> 1.3-5mdk
- extend the regex to match machine with underscore in name

* Mon Oct 17 2005 Daouda LO <daouda@mandriva.com> 1.3-4mdk
- use strict pragma
- call mdkonline::get_release method before computing updates

* Fri Oct 14 2005 Daouda LO <daouda@mandriva.com> 1.3-3mdk
- launch MandrivaUpdate instead of MandrakeUpdate for distro 
  newer than LE2005 (name change policy) #19211

* Wed Oct 05 2005 Daouda LO <daouda@mandriva.com> 1.3-2mdk
- Major update for new SOAP based architecture (only account creation and 
  authentication 
- po updates

* Tue Sep 20 2005 Daouda LO <daouda@mandriva.com> 1.3-1mdk
- fix missing option when calling terminal based mdkonline
- translations update

* Fri Sep 16 2005 Daouda LO <daouda@mandriva.com> 1.3-0.3mdk
- fix bug on auto-upgrading mdkapplet
- limit machine name to alphanum chars and length <= 40

* Thu Sep 15 2005 Daouda LO <daouda@mandriva.com> 1.3-0.2mdk
- use SOAP for client <-> server communication 
  (account creation and authentication through my.mandriva.com)
- http proxy support for SOAP
- merge code amongst releases (10.0, 10.1, LE2005, 2006)

* Mon Aug 22 2005 Daouda LO <daouda@mandriva.com> 1.3-0.1mdk
- 1.3 pre-build for 2006

* Thu Aug 11 2005 Daouda LO <daouda@mandriva.com> 1.2-1mdk
- switch to Mandriva
- po updates

* Wed Apr  6 2005 Daouda LO <daouda@mandrakesoft.com> 1.2-0.1mdk
- better error handling and log messages when server is down or broken
- po updates

* Thu Mar 24 2005 Daouda LO <daouda@mandrakesoft.com> 1.1-32mdk
- best browwser is now handled by /usr/bin/www-browser (#14847)

* Wed Mar 16 2005 Daouda LO <daouda@mandrakesoft.com> 1.1-31mdk
- change Packager to mandrakeonline team
- misc fixes for mnf 
- s/mdkapplet/mdkupdate/ for is_running check
- get root before testing anything


* Wed Mar  9 2005 Daouda LO <daouda@mandrakesoft.com> 1.1-30mdk
- libDrakX stuffs are always located in /usr/lib/ (gb)

* Wed Mar  9 2005 Daouda LO <daouda@mandrakesoft.com> 1.1-29mdk
- added option --interactive (to use nointeractive in MNF)
- MandrakeUpdate in newt version (only for update_source media)
- fix the x86_64 coupled with corporate capharnaum
- No more dns request to check mandrakeonline server's "reachability"
  (release > 10.0) 
- many cleanups

 o Wed Feb 16 2005 Daouda LO <daouda@mandrakesoft.com> 1.1-28mdk
  - don't update kernel
  - added --mnf option to mdkupdate
  - don't check the network if no config file is available

* Wed Jan 19 2005 Daouda LO <daouda@mandrakesoft.com> 1.1-27mdk
- truly support x86_64 (good path to synthesis and RPMS repertory)
- mdkupdate media renamed to update_source (consolidating with MandrakeUpdate)
- fixed last checked date not refreshing

* Wed Dec 29 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-26mdk
- display last check date on applet interface
- fixed permissions of generated conf file (use octal with perl chmod)
- do not go to 'End' step when upload fails, give choice to user 
  to reupload their config 
- added nn.po ( thanks to Karl Ove Hufthammer )

* Fri Dec 10 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-25mdk
- fix typo when --debug is passed to mdkapplet (warly)

* Thu Dec  9 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-24mdk
- don't append protocol when url name is fully qualified (for corporate)
- fixed empty message when update are done
- cosmetics fixes (window sizes, more wait messages)

* Mon Nov 29 2004 Frederic Lepied <flepied@mandrakesoft.com> 1.1-22mdk
- use /corporate/ instead of /Corporate/ in update path.

* Thu Nov 25 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-21mdk
- add online host on GUI (submitted by rwira)
- remerge mdkonline to one package 
- superseded gtk based wizard by interactive one
- MNF support (config upload and misc)
- horodate log strings
- added a debug option to mdkapplet (--debug option)
- check updates fixes

* Tue Oct 26 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-19mdk
- 

* Thu Oct 21 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-19mdk
- branch cvs to MDK10_0_update and MDK10_1 for concurrent devel
- release for 10.0 and corpo
- remove strict requires on drakxtools_newt
- revert urpmi new media handling repositories

* Mon Oct 11 2004 Frederic Lepied <flepied@mandrakesoft.com> 1.1-18mdk
- put the right dependencies on the backend sub-package
- make parsing of output from server more error safe
- create working directory in mdkonline_tui
- po updates

* Tue Oct 05 2004 Rafael Garcia-Suarez <rgarciasuarez@mandrakesoft.com> 1.1-17mdk
- update mdkupdate with new 10.1 mirror structure

* Mon Oct 04 2004 Rafael Garcia-Suarez <rgarciasuarez@mandrakesoft.com> 1.1-16mdk
- rebuild

* Mon Oct  4 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-15mdk
- po updates
- exit code instead of die on mdkupdate

* Fri Oct  1 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-14mdk
- libDrakX is always in %%{_prefix}/lib (gwenole)
- write local and wide configs when Text wizard is used
- use old fashion filehandle

* Thu Sep 30 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-13mdk
- backward compatibilities for mandrakelinux release files
- use correct mdkonline version/release to track down useragent connections
- po updates and perl_checker cleanups
- mdkapplet: decrease timeout for network config check (oblin), we use 10s 
  to refresh now.
- move some functions to mdkonline.pm

* Wed Sep 29 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-12mdk
- introduced mdkonline text based wizard for server products
- po updates
- strict requirement on mdkonline-backend
- new applet status when distrib is not supported (too old or cooker)

* Mon Sep 20 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-10mdk
- upload config into hardware database (hw_client)
- sync config with server every night when mdkupdate is run with option --auto.
- increase update check timeout (every 3h)

* Tue Sep 14 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-9mdk
- po updates

* Fri Sep 10 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-8mdk
- fixed typos in sprintf_fixutf8 and output functions

* Thu Sep  9 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-7mdk
- i18n is back (#11064)
- launch one instance of mdkapplet per desktop.
- resynced po
- remove strings incoherencies
- don't display the same desktop icon for mdkapplet and net_applet
- print errors in popup action area

* Wed Aug  4 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-6mdk
- automatically launch mdkapplet for KDE, GNOME and IceWM (via xinit)

* Sat Jul 17 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-5mdk
- fix conflicts (fcrozat)

* Fri Jul 16 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-4mdk
- added mdkonline backend package for derivative products 
  (MNF, Corporate ...)
- more code shared between apps (wizard, cron update and applet)

* Tue Jun  8 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-3mdk
 o Tue Jun  8 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-2.1.100mdk
   - added misc architectures (ia64, amd64, x86_64, noarch, ppc64)
   - use md5 file check to reload automagically mdkapplet when mdkonline 
     package has changed (install, upgrade or file replacement).

 o Mon May 31 2004 Daouda LO <daouda@mandrakesoft.com> 1.1-1.100mdk
   - Released as mandatory update and tagged as security fix 
     (force applet to update itself).

* Tue May 25 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-8mdk
- fix broken regexp in error handling code (flepied)

* Mon May 17 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-7mdk
- avoid displaying the applet twice on the panel (using fuzzy_pidofs)
- handle network proxy/routing misconfiguration.

* Tue May 11 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-6mdk
- use mouse clock cursor when busy with applet busy icon.
- decrease debug messages

* Mon May 10 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-5mdk
- more meaningful icons set for applet state (big up 2 ln)

* Thu May  6 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-4mdk
- Wed May  5 2004 Frederic Lepied <flepied@mandrakesoft.com> 1.0-4mdk
  o mdkonline:
		* list all countries (tv)
		* fix truncated text (tv)
		* remove shell stuff (tv)
		* force to use the crontab entry

* Wed Apr 28 2004 Frederic Lepied <flepied@mandrakesoft.com> 1.0-3mdk
- fix wrong path in cron entry (#9547)
- po updates
- don't show the window asking for network connection

* Tue Apr 13 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-2mdk
- move mdkonline process and conf files  to /root/.MdkOnline directory (#8621)
- add migration code to ensure compatibility with old versions
- one more fix for rpmvercmp (remove extra shift to avoid comparing numbers and strings)
- better logs
- better timeout for first configuration
- after upgrade, update applet status immediately (do not wait next timeout occurance)

* Wed Mar 24 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-1mdk
- update status when performing 'check updates'
- better perl rpmvercmp for version and release comparisons
- Report status dynamically
- launch applet main window only once
- autograb hostname and prefill wizard fields
- handle error codes from Mandrakeonline server 
- die properly when AUTOSTART is set TO FALSE
- mdkupdate --applet call
- mdkapplet --force to set AUTOSTART to TRUE
- write conf in both auto and applet mode
- po updates (load mdkonline domain for po in mdkappplet)
- bited by chmod novice mode

* Tue Mar  2 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-0.4mdk
- require drakfirsttime (>= 1.0-0.6mdk)
- proxy support (olivier blin)
- some consistencies amongst wizard steps
- bugfixes (refresh, disable applet when quitting...)

* Tue Mar  2 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-0.3mdk
- fix 'display logs'
- set defaults parameters in wizard

* Tue Mar  2 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-0.2mdk
- autostart mdkapplet (KDE/GNOME)
- timeout set to 1 hour checks (decrease server loads).

* Mon Mar  1 2004 Daouda LO <daouda@mandrakesoft.com> 1.0-0.1mdk
- Mandrake Online Resurrected/Rewrited
- Mandrake Applet Notification system
- Wizard for club users is still valid but separated (drakclub executable)

* Mon Feb 24 2003 Daouda LO <daouda@mandrakesoft.com> 0.91-2mdk
- add urpmi source for club member.
- remove icon on gnome desktop (handled in mandrake-galaxy)

* Mon Feb 17 2003 Daouda LO <daouda@mandrakesoft.com> 0.91-1mdk
- rewrite / port to Gtk2.
- MandrakeOnline && MandrakeClub merge.
- spec cleanup.

* Thu Nov 14 2002 Daouda LO <daouda@mandrakesoft.com> 0.18-4mdk
- BuildRequires: gettext (Stefan Van Der Eijk)
- resync with cvs (please use the spec file !)

* Thu Nov 14 2002 Daouda LO <daouda@mandrakesoft.com> 0.18-3mdk
- resync with cvs (please use the spec file !)

* Wed Nov 13 2002 Daouda LO <daouda@mandrakesoft.com> 0.18-2mdk
- release for mandrakeonline.net customers

* Fri Oct 11 2002 Frederic Lepied <flepied@mandrakesoft.com> 0.18-1mdk
- made translations work on page 4
- added mdk standard Makefile rules to build packages

* Fri Oct 11 2002 François Pons <fpons@mandrakesoft.com> 0.17-1mdk
- fixed to make sure the list of rpm is always sent to server.
- use urpmi media for update in order to use non scheduled packages.
- fixed to propagate version to user agent.
- removed most of perl warnings of mdkonline and mdkupdate.
- added missing requires to urpmi.

* Thu Sep 12 2002 Daouda LO <daouda@mandrakesoft.com> 0.16-5mdk
- Use cvs spec file to update package (for Pablo and co)

* Thu Sep 12 2002 Daouda LO <daouda@mandrakesoft.com> 0.16-4mdk
- mdkupdate perl-Locale-gettext move.

* Wed Sep 04 2002 David BAUDENS <baudens@mandrakesoft.com> 0.16-3mdk
- New image

* Mon Sep  2 2002 Daouda LO <daouda@mandrakesoft.com> 0.16-2mdk
- symbolic link for compatibility with old versions
- fix LANG detection 
- cleanups

* Wed Aug 14 2002 Daouda LO <daouda@mandrakesoft.com> 0.16-1mdk
- release 0.16
- add sl drakonline -> mdkonline

* Wed Aug 14 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-27mdk
- mdkonline now in /usr/sbin/ (remove consolehelper aliases)
- better text wrapping.
- good URL.

* Wed Jul 31 2002 David BAUDENS <baudens@mandrakesoft.com> 0.15-26mdk
- Update icon's title

* Wed Jul 31 2002 David BAUDENS <baudens@mandrakesoft.com> 0.15-25mdk
- New 16 & 48 icons.
- Fix "make rpm"

* Sat Jul 20 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-24mdk
- 32 x 32 new icon.

* Wed Jul 17 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-23mdk
- delete redondant 'ftp://' when choosing ftp mirrors

* Tue Jul  9 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-22mdk
- fixes:
		o use no-clobber for wget (prevent multiples downloads of same files)
		o interactive wait message centered
		o cleanups 

* Thu Jun 13 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-21mdk
- moving from test to prod.

* Sun Jun  9 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-20mdk
- bug fixing 
		o chdir/wget to safe directory
		o clean after upgrades

* Wed Apr 17 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-19mdk
- cleanups, 8.1 support.
- drakonline alias.

* Tue Mar 19 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-18mdk
- clean dir after updates.

* Fri Mar 15 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-17mdk
- add desktop entry for gnome.
- po updates

* Thu Mar 14 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-16mdk
- 8.2 release 
- code update 
- automated updates features

* Mon Jan 14 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-15mdk
- add missing png file.

* Mon Jan 14 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-14mdk
- code update
- automated upgrades (working on)
- add URL tag

* Tue Oct 16 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-13mdk
- rebuild against libpng3
- add doc

* Tue Sep 25 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-12mdk
- When you hit the button subscribe, launch the browser and un grayed the 
  next button.

* Tue Sep 25 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-11mdk
- typo in privacy-fr file

* Tue Sep 25 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-10mdk
- updated po.
- spec cleanups.

* Fri Sep 21 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-9mdk
- code update
- definitive links

* Thu Sep 20 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-8mdk
- resync with cvs (Pablo s**)
- switch to usermode
- spec cleanup

* Fri Sep 14 2001 Pablo Saratxaga <pablo@mandrakesoft.com> 0.15-7mdk
- rebuild including latest translations

* Tue Sep 11 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-6mdk
- cvs snapshot
- new http authentification
- cosmetics changes (add icons, paging...)
- no more requires on expect and openssh.

* Sun Sep  2 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-5mdk
- add online subscription feature.

* Fri Aug 31 2001 Renaud Chaillat <rchaillat@mandrakesoft.com> 0.15-4mdk
- fixed exit code from sshlogin script when giving wrong number of args

* Fri Aug 31 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-3mdk
- De po fix.
- No external authentification at this moment. Servers are not ready.

* Fri Aug 31 2001 Renaud Chaillat <rchaillat@mandrakesoft.com> 0.15-2mdk
- added ssh/scp backend with expect scripts
- improved ui
- updated requirements

* Mon Aug 27 2001 Daouda LO <daouda@mandrakesoft.com> 0.15-1mdk
- First mandrake package

