BINARY := robotest
VERSION ?= $(shell git describe --long --tags --always|awk -F'[.-]' '{print $$1 "." $$2 "." $$4}')
NOROOT := -u $$(id -u):$$(id -g)
SRCDIR := /go/src/github.com/gravitational/robotest
BUILDDIR ?= $(abspath build)
DOCKERFLAGS := --rm=true $(NOROOT) -v $(PWD):$(SRCDIR) -v $(BUILDDIR):$(SRCDIR)/build -w $(SRCDIR)
BUILDBOX := robotest:buildbox
GLIDE_VER := v0.12.3

IMAGE_NAME := $(BINARY)-standalone
TARBALL_NAME := $(IMAGE_NAME)-$(VERSION).tar
IMAGE := quay.io/gravitational/$(IMAGE_NAME):$(VERSION)

# Amazon S3
BUILD_BUCKET_URL := s3://clientbuilds.gravitational.io/gravity/latest
S3_OPTS := --region us-east-1

.PHONY: all
all: clean build

.PHONY: build
build: buildbox
	mkdir -p build
	docker run $(DOCKERFLAGS) $(BUILDBOX) make $(BINARY)

$(BINARY): clean
	cd $(SRCDIR) && \
		glide install && \
		go test -c -i ./e2e -o build/$(BINARY)

.PHONY: clean
clean:
	@rm -rf $(BUILDDIR)/$(BINARY)

.PHONY: test
test:
	go test -cover -race -v ./infra/...

buildbox:
	docker build --pull --tag $(BUILDBOX) \
		--build-arg UID=$$(id -u) --build-arg GID=$$(id -g) --build-arg GLIDE_VER=$(GLIDE_VER) .

.PHONY: docker-image
docker-image:
	$(eval TEMPDIR = "$(shell mktemp -d)")
	if [ -z "$(TEMPDIR)" ]; then \
	  echo "TEMPDIR is not set"; exit 1; \
	fi;
	mkdir -p $(TEMPDIR)/build
	BUILDDIR=$(TEMPDIR)/build $(MAKE) build
	cp -r docker/* $(TEMPDIR)/
	cd $(TEMPDIR) && docker build --rm=true -t $(IMAGE) .
	rm -rf $(TEMPDIR)

.PHONY: docker-save
docker-save:
	docker save --output $(TARBALL_NAME) $(IMAGE)

.PHONY: print-image
print-image:
	echo $(IMAGE)

.PHONY: publish
publish: publish-docker-image publish-into-s3

.PHONY: publish-docker-image
publish-docker-image:
	docker push $(IMAGE)

.PHONY: publish-into-s3
publish-into-s3:
	ifeq (, $(shell which aws))
	$(error "No aws command in $(PATH)")
	endif
	aws s3 cp $(NAME).tar $(BUILD_BUCKET_URL)/$(TARBALL_NAME)
