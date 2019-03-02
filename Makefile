DOCKER_IMAGE=varnish
DOCKER_NAMESPACE=nouchka

.DEFAULT_GOAL := build

VERSIONS=4 5 6

build-latest:
	$(MAKE) -s build-version VERSION=latest

build-version:
	@chmod +x ./hooks/build
	DOCKER_TAG=$(VERSION) IMAGE_NAME=$(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):$(VERSION) ./hooks/build

.PHONY: build
build: build-latest
	$(foreach version,$(VERSIONS), $(MAKE) -s build-version VERSION=$(version);)
