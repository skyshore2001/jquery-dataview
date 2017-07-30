SRC=jquery-dataview.js
REL=$(SRC:.js=.min.js)
DOC=$(SRC:.js=.html) README.html

JSMIN=tool/jsmin

all: README.md $(REL) $(DOC)

clean:
	-rm -rf $(REL) $(DOC)

#README.md: $(SRC) tool/gen-readme.pl
#	perl tool/gen-readme.pl $< > $@

%.html: %.md h.inc
	perl tool/filter-md.pl $< | pandoc -f markdown -t html -s --toc -N -H h.inc -o $@

%.html: %.js
	jdcloud-gendoc $^ > $@ || rm -f $@

%.min.js: %.js
	sh -c "$(JSMIN)" < $< > $@

