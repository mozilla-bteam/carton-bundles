S3_BUCKET   = s3://moz-devservices-bmocartons
AWS_PROFILE = bmocartons

DOCKER    = $(SUDO) docker 
BASE_DIR := $(shell pwd)
PERL5LIB := $(BASE_DIR)/lib

IMAGE_TAG  = build-$*
SCRIPTS   := $(wildcard scripts/*)

DIRS     = $(dir $(wildcard */Dockerfile.PL))
BUNDLES = $(addsuffix vendor.tar.gz,$(DIRS))

export PERL5LIB DOCKER SUDO

all: $(BUNDLES)

-include depends.mk

list:
	@for file in $(BUNDLES); do \
		echo $$file; \
	done

build: $(patsubst %/,build-%,$(DIRS))
clean: $(patsubst %/,clean-%,$(DIRS))
upload: $(patsubst %/,upload-%,$(DIRS))

depends.mk: scan-deps $(git ls-files $(DIRS))
	./scan-deps $(DIRS) > $@

%/vendor.tar.gz: build-%
	@echo TAR $@
	@./run-and-copy $(IMAGE_TAG) $@ > $*/run.log

upload-%: %/vendor.tar.gz
	@echo UPLOAD $<
	@aws --profile $(AWS_PROFILE) s3 cp $< $(S3_BUCKET)/$<
	touch $@

build-%: %/Dockerfile %/.dockerignore $(SCRIPTS)
	@echo BUILD $*
	@cd $* && $(DOCKER) build -m 2G -t $(IMAGE_TAG) . > build.log
	@$(DOCKER) images -q $@ > $@

clean-%:
	@echo CLEAN $*
	@echo rm -vf $*/Dockerfile $*/vendor.tar.gz $*/*.log $*/*.tmp

%/Dockerfile: %/Dockerfile.PL lib/Dockerfile.pm $(SCRIPTS)
	perl $< > $@

.DELETE_ON_ERROR: %/Dockerfile %/vendor.tar.gz

%/.dockerignore: .dockerignore
	cp $< $@

.PHOMY: all clean-% build clean list upload
