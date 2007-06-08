PACKAGE = mdkonline
VERSION:=2.17
SVNROOT = svn+ssh://svn.mandriva.com/svn/soft/$(PACKAGE)

NAME = mdkonline
MDKUPDATE = mdkupdate
MDKAPPLET = mdkapplet
SUBDIRS = po

PREFIX = /
DATADIR = $(PREFIX)/usr/share
ICONSDIR = $(DATADIR)/icons
PIXDIR = $(DATADIR)/$(NAME)
SBINDIR = $(PREFIX)/usr/sbin
BINDIR = $(PREFIX)/usr/bin
FBLIBDIR = $(PREFIX)/usr/lib/libDrakX/drakfirsttime
SYSCONFDIR = $(PREFIX)/etc/sysconfig
SBINREL = ../sbin

localedir = $(PREFIX)/usr/share/locale

override CFLAGS += -DPACKAGE=\"$(NAME)\" -DLOCALEDIR=\"$(localedir)\"

all: mdkonline
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

clean:
	$(MAKE) -C po $@
	rm -f core .#*[0-9]
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	find . -name '*~' | xargs rm -f

install: all
	$(MAKE) -C po $@
	install -d $(PREFIX)/usr/{sbin,bin,share/{mime/packages,$(NAME)/pixmaps,autostart,gnome/autostart,icons/{mini,large}},lib/libDrakX/drakfirsttime}
	install -m755 $(NAME) $(SBINDIR)
	install -m755 $(MDKUPDATE) $(SBINDIR)
	install -m755 $(MDKAPPLET) $(BINDIR)
	install -m755 migrate-mdvonline-applet.pl $(SBINDIR)
	install -m644 icons/$(NAME)16.png $(ICONSDIR)/mini/$(NAME).png
	install -m644 icons/$(NAME)32.png $(ICONSDIR)/$(NAME).png
	install -m644 icons/$(NAME)48.png $(ICONSDIR)/large/$(NAME).png
	install -m644 pixmaps/*.png $(PIXDIR)/pixmaps
	install -m644 mdkonline.xml $(DATADIR)/mime/packages/mdkonline.xml
	install -m644 mdkonline.pm $(FBLIBDIR)
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
# mime
	mkdir -p $(DATADIR)/mimelnk/applications/
	install -m644 x-mdv-exec.desktop $(DATADIR)/mimelnk/applications/
	mkdir -p $(PREFIX)/etc/security/console.apps/
	install -m644 console.apps_urpmi.update $(PREFIX)/etc/security/console.apps/urpmi.update
	mkdir -p $(PREFIX)/etc/pam.d
	install -m644 pam.d_urpmi.update $(PREFIX)/etc/pam.d/urpmi.update
	ln -sf consolehelper $(PREFIX)/usr/bin/urpmi.update

# rules to build a test rpm

cleandist:
	rm -rf $(PACKAGE)-$(VERSION) ../$(PACKAGE)-$(VERSION).tar.bz2

localcopy: clean
	svn export -q . $(NAME)-$(VERSION)

tar:
	tar cvf ../$(PACKAGE)-$(VERSION).tar $(PACKAGE)-$(VERSION)
	bzip2 -9vf ../$(PACKAGE)-$(VERSION).tar
	rm -rf $(PACKAGE)-$(VERSION)

# rules to build a distributable rpm

dist: cleandist localcopy tar

log:changelog

changelog: ../common/username
#svn2cl is available in our contrib.
	svn2cl --authors ../common/username.xml --accum
	rm -f ChangeLog.bak
	svn commit -m "Generated by svn2cl the `date '+%c'`" ChangeLog
