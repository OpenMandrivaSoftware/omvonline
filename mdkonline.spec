%define version 1.1
%define name mdkonline
%define release 27mdk

Summary:	The MandrakeOnline Tool  
Name:		%{name}
Version:	%{version}
Release: 	%{release}
Source0:	%{name}-%{version}.tar.bz2
URL:		http://www.mandrakeonline.net
License:	GPL
Group:		System/Configuration/Other
Requires:  	drakxtools-newt, perl-Gtk2-TrayIcon >= 0.03-3mdk, perl-Crypt-SSLeay >= 0.51-2mdk
Provides:   %{name}-backend
Obsoletes:  %{name}-backend
Requires:	hwdb-clients >= 0.15.1-1mdk
BuildRequires: 	gettext, perl-MDK-Common-devel
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch: 	noarch

%description
The MandrakeOnline tool is designed for registered users 
who want to upload their configuration (packages, hardware infos). 
This allows them to be kept informed about security updates, 
hardware support/enhancements and other high value services.
The package include :
* MandrakeOnline wizard for users registration and configuration 
  uploads, 
* Mdkupdate daemon which allows you to install security updates 
  automatically,
* Mdkapplet which is a KDE/Gnome applet for security updates 
  notification and installation. 

%prep
%setup -q

%build

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
cat > $RPM_BUILD_ROOT%{_menudir}/%{name} << EOF
?package(%{name}):\ 
needs="x11" \
icon="mdkonline.png" \
section="Configuration/Other" \
title="Discover custom services" \
longtitle="Wizard tool for online registered user" \
command="/usr/sbin/mdkonline"
EOF

#install menu icon

%post
%{update_menus}

if [ -r /etc/cron.daily/mdkupdate ]; then
  perl -p -i -e 's!/usr/bin/mdkupdate!/usr/sbin/mdkupdate!' /etc/cron.daily/mdkupdate
fi

%postun
%{clean_menus}

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}.lang
%defattr(-,root,root)
%doc COPYING ChangeLog
%{_sbindir}/mdkupdate
%{_sbindir}/mdkonline
%{_sbindir}/drakonline
%{_bindir}/*
%{_prefix}/X11R6/bin/*
%dir %{_prefix}/lib/libDrakX/drakfirsttime
%{_prefix}/lib/libDrakX/drakfirsttime/*.pm
%{_menudir}/%{name}
%{_miconsdir}/*.png
%{_iconsdir}/*.png
%{_liconsdir}/*.png
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
# http://www.linuxmandrake.com/en/cvs.php3)

%changelog
* Wed Jan 19 2005 Daouda LO <daouda@mandrakesoft.com> 1.1-27mdk
- truly support x86_64 (good path to synthesis and RPMS repertory)
- mdkupdate media renamed to update_source (consolidating with MandrakeUpdate)

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

