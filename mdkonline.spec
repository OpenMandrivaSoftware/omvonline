# Changed by Makefile of cvs.
%define version 0.15
%define name mdkonline

Summary:	The Mandrake Online Tool  
Name:		%{name}
Version:	%{version}
Release: 	16mdk
# get the source from our cvs repository (see
# http://www.linuxmandrake.com/en/cvs.php3)
Source0:	%{name}-%{version}.tar.bz2
Source1:	%{name}16.png.bz2
Source2:	%{name}32.png.bz2
Source3:	%{name}48.png.bz2
URL:		http://people.mandrakesoft.com/~daouda/mandrake/mdkonline.html
License:	GPL
Group:		System/Configuration/Other
Requires:	drakxtools >= 1.1.5-97mdk, gtk+mdk, perl-GTK, perl-GTK-GdkImlib, usermode
Requires:	popt >= 1.6, perl-libwww-perl, perl-Crypt-SSLeay >= 0.37
BuildRoot:	%{_tmppath}/%{name}-buildroot
BuildArchitectures: noarch

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

mv ${RPM_BUILD_ROOT}%{_prefix}/X11R6/bin/%{name} \
   ${RPM_BUILD_ROOT}%{_prefix}/X11R6/bin/%{name}.real
ln -sf %{_bindir}/consolehelper ${RPM_BUILD_ROOT}%{_prefix}/X11R6/bin/%{name}

mkdir -p $RPM_BUILD_ROOT%{_sysconfdir}/{pam.d,security/console.apps}
cp pam.%{name} $RPM_BUILD_ROOT%{_sysconfdir}/pam.d/%{name}
cp apps.%{name}  $RPM_BUILD_ROOT%{_sysconfdir}/security/console.apps/%{name}

#install lang
%{find_lang} %{name}

#install menu
mkdir -p $RPM_BUILD_ROOT%{_menudir}
cat > $RPM_BUILD_ROOT%{_menudir}/%{name} << EOF
?package(%{name}):\ 
needs="x11" \
icon="mdkonline.png" \
section="Configuration/Other" \
title="Mandrake Online" \
longtitle="Wizard tool for online registered user" \
command="/usr/X11R6/bin/mdkonline"
EOF

#install menu icon
mkdir -p $RPM_BUILD_ROOT%{_miconsdir}
mkdir -p $RPM_BUILD_ROOT%{_liconsdir}
bzcat %{SOURCE1} > $RPM_BUILD_ROOT%{_miconsdir}/%{name}.png
bzcat %{SOURCE2} > $RPM_BUILD_ROOT%{_iconsdir}/%{name}.png
bzcat %{SOURCE3} > $RPM_BUILD_ROOT%{_liconsdir}/%{name}.png

%post
%{update_menus}

%postun
%{clean_menus}

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}.lang
%defattr(-,root,root)
%doc COPYING
%config(noreplace) %{_sysconfdir}/pam.d/%{name}
%config(noreplace) %{_sysconfdir}/security/console.apps/%{name}
#%{_prefix}/bin/*
%{_prefix}/X11R6/bin/*
%{_bindir}/*
%{_datadir}/%{name}
%{_menudir}/%{name}
%{_miconsdir}/*.png
%{_iconsdir}/*.png
%{_liconsdir}/*.png

%changelog
* Thu Mar 14 2002 Daouda LO <daouda@mandrakesoft.com> 0.15-16mdk
- 8.2 release 
- code update 
- automated updates

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

