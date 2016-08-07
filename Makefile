# change to sudo docker for linux
DOCKER = docker 
BASE_DIR := $(shell pwd)
PERL5LIB := $(BASE_DIR)/lib

IMAGE_TAG  = build-$*
SCRIPTS   := $(wildcard scripts/*)

DIRS     = $(dir $(wildcard */Dockerfile.PL))
TARBALLS = $(addsuffix vendor.tar.gz,$(DIRS))

all: $(TARBALLS)

-include depends.mk

%/vendor.tar.gz: build-%
	./run-and-copy $(IMAGE_TAG) $@ > $*/run.log

build-%: %/Dockerfile %/.dockerignore $(SCRIPTS)
	cd $* && $(DOCKER) build -m 2G -t $(IMAGE_TAG) . > build.log
	docker images -q $@ > $@

%/Dockerfile: %/Dockerfile.PL lib/Dockerfile.pm $(SCRIPTS)
	perl $< > $@

.DELETE_ON_ERROR: %/Dockerfile %/vendor.tar.gz

%/.dockerignore: .dockerignore
	cp $< $@

ifdef CLEAN
clean:
	rm -vf $(CLEAN)/Dockerfile $(CLEAN)/vendor.tar.gz $(CLEAN)/*.log $(CLEAN)/*.tmp
endif

depends.mk: scan-deps $(git ls-files $(DIRS))
	./scan-deps $(DIRS) > $@

clean_all:
	rm -vf */Dockerfile */vendor.tar.gz */*.log */*.tmp

.PHOMY: clean all clean_all
