# Changed by Makefile of cvs.
%define version 0.16
%define name mdkonline

Summary:	The Mandrake Online Tool  
Name:		%{name}
Version:	%{version}
Release: 	2mdk
# get the source from our cvs repository (see
# http://www.linuxmandrake.com/en/cvs.php3)
Source0:	%{name}-%{version}.tar.bz2
URL:		http://www.mandrakeonline.net
License:	GPL
Group:		System/Configuration/Other
Requires:	drakxtools >= 1.1.5-97mdk, gtk+mdk, perl-GTK, perl-GTK-GdkImlib, usermode
Requires:	popt >= 1.6, perl-libwww-perl, perl-Crypt-SSLeay >= 0.37
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArch: noarch

%description
The Mandrake Online tool is designed for registered users 
who want to upload their configuration (packages, hardware infos). 
This allows them to be kept informed about security updates, 
hardware support/enhancements and other high value services.

%prep
%setup -q

%build

%install
rm -rf $RPM_BUILD_ROOT
make prefix=$RPM_BUILD_ROOT install 

#symbolic link to drakonline
ln -sf %_sbindir/mdkonline %buildroot/%_sbindir/drakonline
ln -sf %_sbindir/mdkonline %buildroot/%_prefix/X11R6/bin/mdkonline

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
mkdir -p $RPM_BUILD_ROOT%{_miconsdir}
mkdir -p $RPM_BUILD_ROOT%{_liconsdir}
install -m 0644 $RPM_BUILD_DIR/%name-%version/icons/mdkonline16.png $RPM_BUILD_ROOT%{_miconsdir}/%{name}.png
install -m 0644 $RPM_BUILD_DIR/%name-%version/icons/mdkonline32.png $RPM_BUILD_ROOT%{_iconsdir}/%{name}.png
install -m 0644 $RPM_BUILD_DIR/%name-%version/icons/mdkonline48.png $RPM_BUILD_ROOT%{_liconsdir}/%{name}.png

%post
%{update_menus}

%postun
%{clean_menus}

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}.lang
%defattr(-,root,root)
%doc COPYING
%{_sbindir}/*
%{_bindir}/*
%{_prefix}/X11R6/bin/*
%{_datadir}/%{name}
%{_datadir}/nautilus/default-desktop/gnome-mandrakeonline.desktop
%{_menudir}/%{name}
%{_miconsdir}/*.png
%{_iconsdir}/*.png
%{_liconsdir}/*.png

%changelog
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

