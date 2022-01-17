R := R

default: install

document:
	@$(R) -e "devtools::document()"

check:
	@$(R) -e "devtools::check()"

test:
	@$(R) -e "devtools::test()"

revcheck:
	@$(R) -e "devtools::use_revdep()"
	@$(R) -f "revdep/check.R"

revcheck_reset:
	@$(RCMD) -e "revdepcheck::revdep_reset()"

crancheck:
	@$(R) CMD build .
	@$(R) CMD check *.tar.gz

install:
	$(R) CMD INSTALL ./

README.md: README.Rmd
	$(R) -e "devtools::load_all(); rmarkdown::render('$^')"
	rm README.html

BRANCH := $(shell git branch --show-current | sed 's/[a-z]*\///')
releasePRs:
	@echo Creating PR to master
	@gh pr create -a "@me" -b "" -B master -l "release" -p "Tom" -t "Release $(BRANCH)"
	@echo Creating PR to dev
	@gh pr create -a "@me" -b "" -B dev -l "release" -p "Tom" -t "Release $(BRANCH) into dev"

clean:
	@rm -rf *.tar.gz *.Rcheck revdep
