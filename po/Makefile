# Installation directories
localedir = $(PREFIX)/usr/share/locale

LANGS = $(shell ls *.po | xargs -i basename {} .po )
PGOAL = mdkonline
GOALS = $(PGOAL).pot  $(foreach a, $(LANGS), $(a).mo)

PL_FILES = ../mdkonline ../mdkupdate ../mdkapplet
POFILES = $(shell ls *.po)


# $(foreach a, $(LANGS), $($(a).mo))

all: $(GOALS)

install: all
	for l in $(LANGS); do \
		install -d $(localedir)/$$l/LC_MESSAGES; \
		install -m 644 $$l.mo $(localedir)/$$l/LC_MESSAGES/$(PGOAL).mo; \
	done

clean:
	rm -f *~ *.[oas] *.mo $(GOALS) TAGS

%.mo: %.po
	msgfmt -o $@ $<

%.pot: $(PL_FILES) 
	xgettext -F -n --add-comments='-PO' --keyword=__ --keyword=_ \
		--keyword=N_ --keyword=N \
		--keyword=I_ --keyword=i18n \
		--language=perl -o $@ $(PL_FILES) 

merge: $(PGOAL).pot
	@for n in $(POFILES); do \
		echo "Merging $$n"; \
		msgmerge "$$n" $< > "$$n"t; \
		mv -f "$$n"t "$$n"; \
	done

