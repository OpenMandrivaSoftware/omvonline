# Installation directories
localedir = $(PREFIX)/usr/share/locale

PGOAL = mdkonline

PL_FILES = $(shell cat POTFILES.in | sed 's,^,../,' )
POFILES = $(shell ls *.po)

PL_CFILES = $(PL_FILES:%=%_.c)
POFILES = $(shell ls *.po)
MOFILES = $(POFILES:%.po=%.mo)
LANGS = $(POFILES:%.po=%)

GOALS = $(PGOAL).pot  $(MOFILES)

all: $(GOALS)

install: all
	for l in $(LANGS); do \
		install -d $(localedir)/$$l/LC_MESSAGES; \
		install -m 644 $$l.mo $(localedir)/$$l/LC_MESSAGES/$(PGOAL).mo; \
	done

clean:
	rm -f *~ *.[oas] *.mo $(GOALS) TAGS $(MOFILES) $(PL_CFILES)

%.mo: %.po
	msgfmt -o $@ $<

%.pot: $(PL_CFILES) $(CFILES)
	perl_checker -q --generate-pot $(PGOAL).pot $(PL_FILES)

merge: $(PGOAL).pot
	@for n in $(POFILES); do \
		echo "Merging $$n"; \
		msgmerge "$$n" $< > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done

