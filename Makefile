PACKAGE = mdkonline
VERSION:=$(shell rpm -q --qf '%{VERSION}\n' --specfile $(PACKAGE).spec|head -n 1)
RELEASE:=$(shell rpm -q --qf '%{RELEASE}\n' --specfile $(PACKAGE).spec|head -n 1)
TAG := $(shell echo "V$(VERSION)_$(RELEASE)" | tr -- '-.' '__')

NAME = mdkonline
MDKUPDATE = mdkupdate
MDKAPPLET = mdkapplet
MDKTUI = mdkonline_tui
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
	install -d $(PREFIX)/usr/{sbin,bin,share/{$(NAME)/pixmaps,autostart,icons/{mini,large}},lib/libDrakX/drakfirsttime}
	install -m755 $(NAME) $(SBINDIR)
	install -m755 $(MDKUPDATE) $(SBINDIR)
	install -m755 $(MDKTUI) $(SBINDIR)
	install -m755 $(MDKAPPLET) $(BINDIR)
	install -m644 icons/$(NAME)16.png $(ICONSDIR)/mini/$(NAME).png
	install -m644 icons/$(NAME)32.png $(ICONSDIR)/$(NAME).png
	install -m644 icons/$(NAME)48.png $(ICONSDIR)/large/$(NAME).png
	install -m644 pixmaps/*.png $(PIXDIR)/pixmaps
#	install -m644 mdkapplet.desktop $(PREFIX)/usr/share/autostart/
	install -m644 mdkonline.pm $(FBLIBDIR)
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

# rules to build a test rpm

localrpm:  clean localdist buildrpm

localdist: cleandist dir localcopy tar

cleandist:
	rm -rf $(PACKAGE)-$(VERSION) ../$(PACKAGE)-$(VERSION).tar.bz2

dir:
	mkdir $(PACKAGE)-$(VERSION)

localcopy: clean
	find . -not -name "$(PACKAGE)-$(VERSION)" -a -not -name '*.bz2'|cpio -pd $(PACKAGE)-$(VERSION)/
	find $(PACKAGE)-$(VERSION) -type d -name CVS|xargs rm -rf 

tar:
	tar cvf ../$(PACKAGE)-$(VERSION).tar $(PACKAGE)-$(VERSION)
	bzip2 -9vf ../$(PACKAGE)-$(VERSION).tar
	rm -rf $(PACKAGE)-$(VERSION)

buildrpm:
	rpm -ta ../$(PACKAGE)-$(VERSION).tar.bz2
	rm -f ../$(PACKAGE)-$(VERSION).tar.bz2

# rules to build a distributable rpm

rpm: changelog cvstag dist buildrpm

dist: cleandist dir export tar

export:
	cvs export -d $(PACKAGE)-$(VERSION) -r $(TAG) $(PACKAGE)

cvstag:
	cvs tag $(CVSTAGOPT) $(TAG)

changelog: ../common/username
	cvs2cl -U ../common/username -I ChangeLog 
	rm -f ChangeLog.bak
	cvs commit -m "Generated by cvs2cl the `date '+%d_%b'`" ChangeLog
