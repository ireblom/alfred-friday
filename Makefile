GITVERSION=gitversion
GITVERSION_ARGS=
GNU_SED=gsed
GPG=gpg
GPG_ARGS=--armor --detach-sign
MD5=md5
MD5_ARGS=-r
PYTHON=/usr/bin/python
SHA=shasum
SHA_ARGS=-a
XMLLINT=xmllint
XMLLINT_ARGS=--format --noblanks --valid --output
ZIP=zip
ZIP_ARGS=-r -9 -X -j

BUILD_DIR=./out
ARTIFACT_DIR=./artifacts

WORKFLOW_NAME=alfred-friday
ifeq ($(strip $(GITVERSION)),)
	WORKFLOW_VERSION=?
	WORKFLOW_NAME_AND_VERSION=$(WORKFLOW_NAME)
else
	WORKFLOW_VERSION=$(shell $(GITVERSION) $(GITVERSION_ARGS) | $(PYTHON) $(PYTHON_ARGS)-c "import sys, json; print json.load(sys.stdin)['SemVer']")
	WORKFLOW_NAME_AND_VERSION=$(WORKFLOW_NAME)-v$(WORKFLOW_VERSION)
endif
WORKFLOW_CONTENTS=info.plist icon.png LICENSE
WORKFLOW_BINARY=$(WORKFLOW_NAME_AND_VERSION).alfredworkflow

ARTIFACT_FILES=$(WORKFLOW_BINARY)

.PHONY: all
all: install

.PHONY: install
install: workflow
	open $(ARTIFACT_DIR)/$(WORKFLOW_BINARY)

.PHONY: dist
dist: workflow checksum sign

.PHONY: workflow
workflow: $(addprefix $(ARTIFACT_DIR)/,$(WORKFLOW_BINARY))

$(ARTIFACT_DIR):
	mkdir -p $(@)

$(ARTIFACT_DIR)/$(WORKFLOW_BINARY): $(addprefix $(BUILD_DIR)/,$(WORKFLOW_CONTENTS)) |$(ARTIFACT_DIR)
	rm -f $@
	$(ZIP) $(ZIP_ARGS) $@ $(^)

.PHONY: build
build: $(addprefix $(BUILD_DIR)/,$(WORKFLOW_CONTENTS))

$(BUILD_DIR):
	mkdir -p $(@)

$(BUILD_DIR)/info.plist: info.plist workflow-readme |$(BUILD_DIR)
	cat $< \
	| $(GNU_SED) \
	-e "s/ALFRED_FRIDAY_VERSION/$(WORKFLOW_VERSION)/" \
	-e "s/ALFRED_FRIDAY_README/$$(<workflow-readme sed -e 's/[\&/]/\\&/g' -e 's/$$/\\n/g' | tr -d '\n')/" \
	| $(XMLLINT) \
	$(XMLLINT_ARGS) $@ -

$(BUILD_DIR)/%: % |$(BUILD_DIR)
	cp -f $< $@

.PHONY: checksum
checksum: md5 sha1 sha256 sha512

.PHONY: md5
md5: $(ARTIFACT_DIR)/CHECKSUM.MD5-$(WORKFLOW_NAME_AND_VERSION)

$(ARTIFACT_DIR)/CHECKSUM.MD5-$(WORKFLOW_NAME_AND_VERSION): $(addprefix $(ARTIFACT_DIR)/,$(ARTIFACT_FILES))
	(cd $(@D) && $(MD5) $(MD5_ARGS) $(ARTIFACT_FILES) > $(@F))

.PHONY: sha1
sha256: $(ARTIFACT_DIR)/CHECKSUM.SHA1-$(WORKFLOW_NAME_AND_VERSION)

.PHONY: sha256
sha256: $(ARTIFACT_DIR)/CHECKSUM.SHA256-$(WORKFLOW_NAME_AND_VERSION)

.PHONY: sha512
sha512: $(ARTIFACT_DIR)/CHECKSUM.SHA512-$(WORKFLOW_NAME_AND_VERSION)

$(ARTIFACT_DIR)/CHECKSUM.SHA%-$(WORKFLOW_NAME_AND_VERSION): $(addprefix $(ARTIFACT_DIR)/,$(ARTIFACT_FILES))
	(cd $(@D) && $(SHA) $(SHA_ARGS) $* $(ARTIFACT_FILES) > $(@F))

.PHONY: sign
sign: $(addsuffix .asc,$(addprefix $(ARTIFACT_DIR)/,$(ARTIFACT_FILES)))

%.asc: %
	(cd $(@D) && $(GPG) $(GPG_ARGS) $(<F))

.PHONY: clean
clean:
	rm -rf "$(BUILD_DIR)"
	rm -rf "$(ARTIFACT_DIR)"
