NAME      = bmo
IMAGE_TAG = $(NAME)-carton
# change to sudo docker for linux
DOCKER = docker 
SCRIPTS := $(wildcard scripts/*)
FILES   := $(shell git ls-files $(NAME))

include $(NAME)/vars.mk

$(NAME)/vendor.tar.gz: $(NAME)/image-id
	./copy-file $< /vendor.tar.gz $@

$(NAME)/image-id: $(NAME)/Dockerfile $(SCRIPTS)
	cp -a scripts/* $(NAME)
	cd $(NAME) && $(DOCKER) build -m 2G -t $(IMAGE_TAG) . > build.log
	$(DOCKER) images -q $(IMAGE_TAG) > $@

$(NAME)/Dockerfile: Dockerfile.PL $(FILES)
	( cd $(NAME) && perl ../$< ) > $@

$(NAME)/include.pl:
	touch $@

clean:
	rm -fv $(NAME)/image-id \
		   $(NAME)/Dockerfile \
		   $(NAME)/vendor.tar.gz \
		   $(patsubst scripts/%,$(NAME)/%,$(SCRIPTS)) \
		   $(NAME)/build.log

.PHOMY: clean
