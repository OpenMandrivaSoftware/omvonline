%define version 1.0
%define name mdkonline

Summary:	The MandrakeOnline Tool  
Name:		%{name}
Version:	%{version}
Release: 	4mdk
Source0:	%{name}-%{version}.tar.bz2
URL:		http://www.mandrakeonline.net
Packager:	Daouda Lo <daouda@mandrakesoft.com>
License:	GPL
Group:		System/Configuration/Other
Requires:	drakfirsttime >= 1.0-0.6mdk, perl-Crypt-SSLeay >= 0.51-2mdk, perl-Gtk2-TrayIcon >= 0.03-3mdk
BuildRequires: gettext
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch: noarch

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
%{_sbindir}/*
%{_bindir}/*
%{_prefix}/X11R6/bin/*
%{_menudir}/%{name}
%{_miconsdir}/*.png
%{_iconsdir}/*.png
%{_liconsdir}/*.png
%{_datadir}/%{name}/pixmaps/*.png
%{_datadir}/autostart/*

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
* Wed May  5 2004 Frederic Lepied <flepied@mandrakesoft.com> 1.0-4mdk
- mdkonline:
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

