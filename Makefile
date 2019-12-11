DOCKER_IMAGE=varnish
VERSIONS=4 5 6

include Makefile.docker

.PHONY: check-version
check-version:
	docker run --rm $(DOCKER_NAMESPACE)/$(DOCKER_IMAGE):$(VERSION) dpkg-query --showformat='$${Version} ' --show $(DOCKER_IMAGE)
