# Changed by Makefile of cvs.
%define version 0.15
%define name mdkonline

Summary:	The Mandrake Online Tool  
Name:		%{name}
Version:	%{version}
Release: 5mdk
# get the source from our cvs repository (see
# http://www.linuxmandrake.com/en/cvs.php3)
Source0:	%{name}-%{version}.tar.bz2
#Source1:	%{name}16.xpm.bz2
#Source2:	%{name}32.xpm.bz2
#Source3:	%{name}48.xpm.bz2
License:	GPL
Group:		System/Configuration/Other
Requires:	drakxtools >= 1.1.5-97mdk, gtk+mdk, perl-GTK, perl-GTK-GdkImlib, usermode
Requires:	popt >= 1.6, 
Requires: expect
Requires: openssh-clients
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

#install lang
%{find_lang} %{name}

#install menu
mkdir -p $RPM_BUILD_ROOT%{_menudir}
cat > $RPM_BUILD_ROOT%{_menudir}/%{name} << EOF
?package(%{name}):\ 
needs="x11" \
icon="mdkonline.xpm" \
section="Configuration/Other" \
title="Mandrake Online" \
longtitle="Wizard tool for online registered user" \
command="/usr/X11R6/bin/mdkonline"
EOF

#install menu icon
mkdir -p $RPM_BUILD_ROOT%{_miconsdir}
mkdir -p $RPM_BUILD_ROOT%{_liconsdir}
#bzcat %{SOURCE1} > $RPM_BUILD_ROOT%{_miconsdir}/%{name}.xpm
#bzcat %{SOURCE2} > $RPM_BUILD_ROOT%{_iconsdir}/%{name}.xpm
#bzcat %{SOURCE3} > $RPM_BUILD_ROOT%{_liconsdir}/%{name}.xpm

%post
%{update_menus}

%postun
%{clean_menus}

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}.lang
%defattr(-,root,root)
%{_prefix}/bin/*
%{_prefix}/X11R6/bin/*
%{_datadir}/%{name}
%{_menudir}/%{name}
#%{_miconsdir}/*.xpm
#%{_iconsdir}/*.xpm
#%{_liconsdir}/*.xpm

%changelog
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

