# Installation directories
localedir = $(prefix)/usr/share/locale

LANGS = $(shell ls *.po | xargs -i basename {} .po )
PGOAL = mdkonline
GOALS = $(PGOAL).pot  $(foreach a, $(LANGS), $(a).mo)

PL_FILES = ../mdkonline ../mdkupdate
PL_CFILES = $(PL_FILES:%=%_.c)

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

$(PL_CFILES): %_.c: %
	./fake_c.pl $< > $@

%.pot: $(PL_CFILES) 
	xgettext -F -n --add-comments='-PO' --keyword=__ --keyword=_ \
		--keyword=N_ --keyword=N \
		--keyword=I_ --keyword=i18n \
		--language=C -o $@ $(PL_CFILES) 
	@rm -rf $(PL_CFILES)

