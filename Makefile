SHELL := /bin/bash

# Ensure the xml2rfc cache directory exists locally
IGNORE := $(shell mkdir -p $(HOME)/.cache/xml2rfc)

# Check which yq it is.
# Use duck-typing.
IS_YQ_CORRECT := $(shell yq --help | grep 'yq r')
ifeq ($(IS_YQ_CORRECT),)
	$(error The 'yq' at your PATH is not the 'yq' we use.  Use this version instead: https://github.com/mikefarah/yq )
endif

PUBLISHING_DIRECTORY ?= published

SRC := $(shell yq r metanorma.yml metanorma.source.files | cut -c 3-999)
ifeq ($(SRC),ll)
	SRC := $(filter-out README.adoc, $(wildcard sources/*.adoc))
endif

# The list $(FORMAT_MARKER) found in source files will determine the output
# formats used by this Makefile.
FORMAT_MARKER := mn-output-
FORMATS       := $(shell grep "$(FORMAT_MARKER)" $(SRC) | cut -f 2 -d ' ' | tr ',' '\n' | sort | uniq | tr '\n' ' ')

# List out all potential input-to-output formats here.
XML     := $(patsubst sources/%,documents/%,$(patsubst %.adoc,%.xml,$(SRC)))
XMLRFC3 := $(patsubst %.xml,%.v3.xml,$(XML))
HTML    := $(patsubst %.xml,%.html,$(XML))
DOC     := $(patsubst %.xml,%.doc,$(XML))
PDF     := $(patsubst %.xml,%.pdf,$(XML))
TXT     := $(patsubst %.xml,%.txt,$(XML))
NITS    := $(patsubst %.adoc,%.nits,$(wildcard sources/draft-*.adoc))
WSD     := $(wildcard sources/models/*.wsd)
XMI     := $(patsubst sources/models/%,sources/xmi/%,$(patsubst %.wsd,%.xmi,$(WSD)))
PNG     := $(patsubst sources/models/%,sources/images/%,$(patsubst %.wsd,%.png,$(WSD)))

# Only use `npm -g` if npm global prefix is writable
NPM_IS_GLOBAL := $(shell test -w $$(npm -g prefix) && echo 1)
NPM_OPTS      := $(if $(NPM_IS_GLOBAL),-g)
NPM           ?= npm
NPM_COMMAND   := $(NPM) $(NPM_OPTS)
NPM_BIN       := `$(NPM_COMMAND) bin`

NODE_BINS          := onchange live-serve run-p
NODE_BIN_DIR       := node_modules/.bin
NODE_PACKAGE_PATHS := $(foreach PACKAGE_NAME,$(NODE_BINS),$(NODE_BIN_DIR)/$(PACKAGE_NAME))

PLANTUML ?= plantuml

COMPILE_CMD_LOCAL := bundle exec metanorma $$FILENAME
COMPILE_CMD_DOCKER := docker run -v "$$(pwd)":/metanorma/ ribose/metanorma "metanorma $$FILENAME"

ifdef METANORMA_DOCKER
	COMPILE_CMD := echo "Compiling via docker..."; $(COMPILE_CMD_DOCKER)
else
	COMPILE_CMD := echo "Compiling locally..."; $(COMPILE_CMD_LOCAL)
endif

# $(OUT_FILES) is only used for cleaning up.
_OUT_FILES := $(foreach FORMAT,$(FORMATS),$(shell echo $(FORMAT) | tr '[:lower:]' '[:upper:]'))
OUT_FILES  := $(foreach F,$(_OUT_FILES),$($F))

.PHONY: all
all: prep documents.html ## Compile everything

.PHONY: help
help: ## Print help for targets with comments
	@cat $(MAKEFILE_LIST) | grep -E '^[.a-zA-Z_-]+:.*?## .*$$' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: prep
prep: Gemfile Gemfile.lock package.json package-lock.json $(NPM_DECKTAPE_DEPS) ## Install build dependencies "if needed"
	@for gem in \
		metanorma \
		relaton \
		; do bundle exec "$$gem" --version 2>/dev/null 1>&2 || { echo "$${gem} not found. Running 'make bundle'." ; make bundle ; } ; done

documents.html: documents.rxl
	bundle exec relaton xml2html documents.rxl

documents.rxl: $(XML)
	bundle exec relaton concatenate \
	  -t "$(shell yq r metanorma.yml relaton.collection.name)" \
		-g "$(shell yq r metanorma.yml relaton.collection.organization)" \
		documents $@

documents:
	mkdir -p $@

%.xml %.html %.doc %.txt %.v3.xml %.pdf: %.adoc
	FILENAME=$^; \
	${COMPILE_CMD}

# %.v3.xml %.xml %.html %.doc %.pdf %.txt: sources/images %.adoc | bundle
# 	FILENAME=$^; \
# 	${COMPILE_CMD}
#
# documents/draft-%.nits:	documents/draft-%.txt
# 	VERSIONED_NAME=`grep :name: draft-$*.adoc | cut -f 2 -d ' '`; \
# 	cp $^ $${VERSIONED_NAME}.txt && \
# 	idnits --verbose $${VERSIONED_NAME}.txt > $@ && \
# 	cp $@ $${VERSIONED_NAME}.nits && \
# 	cat $${VERSIONED_NAME}.nits

# %.nits:

# %.adoc:

nits: $(NITS)

sources/images: $(PNG)

sources/images/%.png: sources/models/%.wsd
	$(PLANTUML) -tpng -o ../images/ $<

sources/xmi: $(XMI)

sources/xmi/%.xmi: sources/models/%.wsd
	$(PLANTUML) -xmi:star -o ../xmi/ $<

define FORMAT_TASKS
OUT_FILES-$(FORMAT) := $($(shell echo $(FORMAT) | tr '[:lower:]' '[:upper:]'))

documents/%.$(FORMAT): documents sources/images sources/%.$(FORMAT)
	export GLOBIGNORE=sources/$$*.adoc; \
		cp sources/$$(addsuffix .*,$$*) documents

.PHONY: open-$(FORMAT)
open-$(FORMAT): ## Open(1) the compiled $(FORMAT) file(s)
	open $$(OUT_FILES-$(FORMAT))

.PHONY: clean-$(FORMAT)
clean-$(FORMAT): ## Remove the compiled $(FORMAT) file(s)
	rm -f $$(OUT_FILES-$(FORMAT))

$(FORMAT): clean-$(FORMAT) $$(OUT_FILES-$(FORMAT))

endef

$(foreach FORMAT,$(FORMATS),$(eval $(FORMAT_TASKS)))

.PHONY: open
open: open-html ## Open(1) the compiled file(s)

.PHONY: clean
clean: ## Remove all generated files
	rm -rf .tmp.xml documents documents.html documents.rxl $(PUBLISHING_DIRECTORY) *_images $(OUT_FILES) sources/*.{doc,html,rxl,xml}

.PHONY: bundle
bundle: Gemfile Gemfile.lock ## Run `bundle` to install bundled Ruby gem dependencies
	[[ -n "${METANORMA_DOCKER}" ]] || bundle


#
# Watch-related jobs
#

$(NODE_PACKAGE_PATHS): package.json
	[[ -x $@ ]] || $(NPM_COMMAND) install
	# $(NPM_COMMAND) install

.PHONY: watch
watch: $(NODE_BIN_DIR)/onchange
	make all
	$< $(ALL_SRC) -- make all

define WATCH_TASKS
.PHONY: watch-$(FORMAT)
watch-$(FORMAT): $(NODE_BIN_DIR)/onchange
	make $(FORMAT)
	$$< $$(SRC_$(FORMAT)) -- make $(FORMAT)

endef

$(foreach FORMAT,$(FORMATS),$(eval $(WATCH_TASKS)))

.PHONY: serve
serve: $(NODE_BIN_DIR)/live-server sources/images ## Run an HTTP server on PORT (default 8123)
	export PORT=$${PORT:-8123} ; \
	port=$${PORT} ; \
	for html in $(HTML); do \
		$< --entry-file=$$html --port=$${port} --ignore="*.html,*.xml,Makefile,Gemfile.*,package.*.json" --wait=1000 & \
		port=$$(( port++ )) ;\
	done

.PHONY: watch-serve
watch-serve: $(NODE_BIN_DIR)/run-p ## Run an HTTP server on PORT (default 8123) that compiles afresh on file changes
	$< watch serve

#
# Deploy jobs
#

$(PUBLISHING_DIRECTORY):
	mkdir -p $(PUBLISHING_DIRECTORY)

$(PUBLISHING_DIRECTORY)/documents: $(OUT_FILES)
	cp -a documents $(PUBLISHING_DIRECTORY)/
	# cp -a $< $(PUBLISHING_DIRECTORY)/

$(PUBLISHING_DIRECTORY)/index.html: documents.html
	cp $< $@

$(PUBLISHING_DIRECTORY)/sources/images: sources/images
	cp -a $< $(PUBLISHING_DIRECTORY)/

.PHONY: publish

## Copy compiled HTML files to the specified
## PUBLISHING_DIRECTORY folder (default: published/)
publish: $(PUBLISHING_DIRECTORY) $(PUBLISHING_DIRECTORY)/documents $(PUBLISHING_DIRECTORY)/index.html $(PUBLISHING_DIRECTORY)/sources/images
