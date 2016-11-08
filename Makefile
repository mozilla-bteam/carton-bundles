S3_BUCKET   = moz-devservices-bmocartons
S3_BUCKET_URI = https://$(S3_BUCKET).s3.amazonaws.com
AWS_PROFILE = bmocartons

DOCKER    = $(SUDO) docker 
BASE_DIR := $(shell pwd)
PERL5LIB := $(BASE_DIR)/lib
VERSION  := $(shell git show --oneline | awk '$$1 {print $$1}')

IMAGE_TAG  = build-$*
SCRIPTS   := $(wildcard scripts/*)

DIRS     = $(dir $(wildcard */Dockerfile.PL))
BUNDLES = $(addsuffix vendor.tar.gz,$(DIRS))

export PERL5LIB DOCKER SUDO S3_BUCKET_URI

list:
	@for dir in $(DIRS); do \
		echo $$(basename $$dir); \
	done

-include depends.mk

bundles: $(BUNDLES)
build: $(patsubst %/,build-%,$(DIRS))
clean: $(patsubst %/,clean-%,$(DIRS))
upload: $(patsubst %/,upload-%,$(DIRS))
snapshots: $(BUNDLES)
	for bundle in $(BUNDLES); do \
		file="$$(dirname $$bundle)/cpanfile.snapshot"; \
		tar -zxf $$bundle $$file; \
		git add $$file; \
	done

depends.mk: scan-deps $(git ls-files $(DIRS))
	./scan-deps $(DIRS) > $@

%/vendor.tar.gz: build-%
	@echo TAR $@
	@./run-and-copy --image "$(IMAGE_TAG)" --cmd build-bundle /vendor.tar.gz $@ > $*/run.log

upload-%: %/vendor.tar.gz
	@echo UPLOAD $<
	@aws --profile $(AWS_PROFILE) s3 cp $< s3://$(S3_BUCKET)/$<
	touch $@

build-%: %/Dockerfile %/.dockerignore $(SCRIPTS) 
	@echo BUILD $*
	@cd $* && $(DOCKER) build -m 2G -t $(IMAGE_TAG) . > build.log
	@$(DOCKER) images -q $@ > $@

clean-%:
	@echo CLEAN $*
	@rm -vf $*/Dockerfile $*/vendor.tar.gz $*/*.log $*/*.tmp

%/Dockerfile: %/Dockerfile.PL lib/Dockerfile.pm $(SCRIPTS)
	perl $< > $@

.DELETE_ON_ERROR: %/Dockerfile %/vendor.tar.gz

%/.dockerignore: .dockerignore
	cp $< $@

.PHONY: bundles clean-% build clean list upload snapshots
