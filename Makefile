VERSION = $(shell awk '/define version/ { print $$3 }' $(NAME).spec)
NAME = mdkonline
SUBDIRS = po
localedir = $(prefix)/usr/share/locale
RPM=$(HOME)/RPM

override CFLAGS += -DPACKAGE=\"$(NAME)\" -DLOCALEDIR=\"$(localedir)\"

all: mdkonline
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

clean:
	$(MAKE) -C po $@
	rm -f core .#*[0-9]
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

install: all
	$(MAKE) -C po $@
	install -d $(RPM_BUILD_ROOT)/usr/{X11R6/bin/,share/icons,share/mdkonline/pixmaps}
	install -s -m755 $(NAME) $(RPM_BUILD_ROOT)/usr/X11R6/bin/
#	install -m644 icons/*.png $(RPM_BUILD_ROOT)/usr/share/icons/
	install -m644 pixmaps/*.png $(RPM_BUILD_ROOT)/usr/share/mdkonline/pixmaps
	for d in $(SUBDIRS); do ( cd $$d ; make $@ ) ; done

dis: clean
	rm -rf $(NAME)-$(VERSION) ../$(NAME)-$(VERSION).tar*
	cvs commit 
	mkdir -p $(NAME)-$(VERSION)
	find . -not -name "$(NAME)-$(VERSION)"|cpio -pd $(NAME)-$(VERSION)/
	find $(NAME)-$(VERSION) -type d -name CVS -o -name .cvsignore |xargs rm -rf
	tar cf ../$(NAME)-$(VERSION).tar $(NAME)-$(VERSION)
	bzip2 -9f ../$(NAME)-$(VERSION).tar
	rm -rf $(NAME)-$(VERSION)

rpm: dis ../$(NAME)-$(VERSION).tar.bz2 $(RPM)
	cp -f ../$(NAME)-$(VERSION).tar.bz2 $(RPM)/SOURCES
#	cp -f *.xpm.bz2 $(RPM)/SOURCES
	cp -f $(NAME).spec $(RPM)/SPECS/
	rpm -ba --clean --rmsource $(NAME).spec
	rm -f ../$(NAME)-$(VERSION).tar.bz2
