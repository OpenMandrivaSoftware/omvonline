# Installation directories
localedir = $(PREFIX)/usr/share/locale

PGOAL = omvonline

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
	rm -f *~ *.[oas] *.mo TAGS $(PL_CFILES)

%.mo: %.po
	msgfmt -o $@ $<

$(PGOAL).pot: $(PL_FILES) $(CFILES)
	perl_checker -q --generate-pot $(PGOAL).pot $(PL_FILES)

update_n_merge: $(PGOAL).pot merge

merge:
	@for n in $(POFILES); do \
		echo "Merging $$n"; \
		msgmerge "$$n" $(PGOAL).pot > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done

