DOCKER_TAG=4

test:
	export DOCKER_TAG=$(DOCKER_TAG);export IMAGE_NAME=nouchka/varnish:$(DOCKER_TAG); ./hooks/build
