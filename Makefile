PACKAGE = omvonline
VERSION:=2.78.1
SVNROOT = svn+ssh://svn.mandriva.com/svn/soft/$(PACKAGE)

NAME = omvonline
MDKUPDATE = omvupdate
MDKAPPLET = omvapplet
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

all:
	(find -name .svn -prune -name '*.pm' -o -name omvapplet\* -o -name omvupdate -o -name omvonline_agent.pl -type f) | xargs perl -pi -e 's/\s*use\s+(diagnostics|vars|strict).*//g'
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

clean:
	$(MAKE) -C po $@
	rm -f core .#*[0-9]
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done
	find . -name '*~' | xargs rm -f

install: all
	install -d $(PREFIX)/usr/{sbin,bin,share/{mime/packages,$(NAME)/pixmaps,autostart,gnome/autostart,icons/{mini,large}},lib/libDrakX/drakfirsttime}
	install -m755 $(MDKUPDATE) $(SBINDIR)
	install -m755 $(MDKAPPLET) $(BINDIR)
	install -d $(SYSCONFDIR)
	install -m644 omvapplet.conf $(SYSCONFDIR)/omvapplet
	install -m644 icons/$(NAME)16.png $(ICONSDIR)/mini/$(NAME).png
	install -m644 icons/$(NAME)32.png $(ICONSDIR)/$(NAME).png
	install -m644 icons/$(NAME)48.png $(ICONSDIR)/large/$(NAME).png
	install -m644 pixmaps/*.png $(PIXDIR)/pixmaps
	perl -pi -e "s/version = 1/version = '$(VERSION)'/" omvonline.pm
	install -m644 omvonline.pm $(FBLIBDIR)
	install -m644 omvapplet_gui.pm $(FBLIBDIR)
	install -m644 omvapplet_urpm.pm $(FBLIBDIR)
	for d in $(SUBDIRS); do make -C $$d $@; done
# mime
	install -m644 omvonline.xml $(DATADIR)/mime/packages/omvonline.xml
	mkdir -p $(DATADIR)/mimelnk/application/
	install -m644 x-omv-exec.desktop $(DATADIR)/mimelnk/application/
	mkdir -p $(PREFIX)/etc/security/console.apps/
	install -m644 console.apps_urpmi.update $(PREFIX)/etc/security/console.apps/urpmi.update
	mkdir -p $(PREFIX)/etc/pam.d
	install -m644 pam.d_urpmi.update $(PREFIX)/etc/pam.d/urpmi.update
	ln -sf consolehelper $(PREFIX)/usr/bin/urpmi.update
	for i in omvapplet-config omvapplet-add-media-helper omvapplet-upgrade-helper; do \
		install -m755 $$i $(SBINDIR); \
		ln -sf consolehelper $(PREFIX)/usr/bin/$$i; \
	done

cleandist:
	rm -rf $(PACKAGE)-$(VERSION) ../$(PACKAGE)-$(VERSION).tar.bz2


dis: dist
dist:
	@make cleandist
	rm -rf ../$(NAME)-$(VERSION).tar*
	@if [ -e ".svn" ]; then \
		$(MAKE) dist-svn; \
	elif [ -e ".git" ]; then \
		$(MAKE) dist-git; \
	else \
		echo "Unknown SCM (not SVN nor GIT)";\
		exit 1; \
	fi;
	$(info $(NAME)-$(VERSION).tar.xz is ready)

dist-svn:
	rm -rf $(NAME)-$(VERSION)
	svn export -q -rBASE . $(NAME)-$(VERSION)
	tar cfa ../$(PACKAGE)-$(VERSION).tar.xz $(PACKAGE)-$(VERSION)
	rm -rf $(NAME)-$(VERSION)


dist-git:
	 @git archive --prefix=$(NAME)-$(VERSION)/ HEAD | xz >../$(NAME)-$(VERSION).tar.xz;

log:changelog

changelog: ../common/username
#svn2cl is available in our contrib.
	svn2cl --authors ../common/username.xml --accum
	rm -f ChangeLog.bak
	svn commit -m "Generated by svn2cl the `date '+%c'`" ChangeLog
