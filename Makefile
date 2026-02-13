# Makefile for xdg-desktop-portal-openuri
# SPDX-License-Identifier: MIT

# Variables
BINARY = xdg-desktop-portal-openuri
SOURCE = xdg-desktop-portal-openuri.c
BUILD_DIR = build
CFLAGS = $(shell pkg-config --cflags gio-2.0 glib-2.0 gtk+-3.0)
LDFLAGS = $(shell pkg-config --libs gio-2.0 glib-2.0 gtk+-3.0)

IMAGE_NAME ?= playtron/xdg-desktop-portal-openuri-builder
IMAGE_TAG ?= latest

PREFIX ?= $(HOME)/.local

VERSION := $(shell grep -E '^Version:' xdg-desktop-portal-openuri.spec | awk '{print $$2}')

# Default target
.PHONY: all
all: build

# Build the binary into the build folder
.PHONY: build
build: check-build-deps $(BUILD_DIR)/$(BINARY)

$(BUILD_DIR)/$(BINARY): $(SOURCE)
	@mkdir -p $(BUILD_DIR)
	gcc -o $(BUILD_DIR)/$(BINARY) $(SOURCE) $(CFLAGS) $(LDFLAGS)

.PHONY: rpm-setup
rpm-setup:
	mkdir -p /tmp/rpmbuild/BUILD
	mkdir -p /tmp/rpmbuild/RPMS
	mkdir -p /tmp/rpmbuild/SOURCES
	mkdir -p /tmp/rpmbuild/SPECS
	mkdir -p /tmp/rpmbuild/SRPMS
	cp ./xdg-desktop-portal-openuri.spec /tmp/rpmbuild/SPECS/
	rm -rf /tmp/rpmbuild/SOURCES/xdg-desktop-portal-openuri-$(VERSION)
	mkdir -p /tmp/rpmbuild/SOURCES/xdg-desktop-portal-openuri-$(VERSION)
	cp -r ./build /tmp/rpmbuild/SOURCES/xdg-desktop-portal-openuri-$(VERSION)/build
	cp -r ./rootfs /tmp/rpmbuild/SOURCES/xdg-desktop-portal-openuri-$(VERSION)/rootfs
	cp ./Makefile /tmp/rpmbuild/SOURCES/xdg-desktop-portal-openuri-$(VERSION)/
	cp ./LICENSE /tmp/rpmbuild/SOURCES/xdg-desktop-portal-openuri-$(VERSION)/
	cp ./README.md /tmp/rpmbuild/SOURCES/xdg-desktop-portal-openuri-$(VERSION)/
	cd /tmp/rpmbuild/SOURCES && tar czf xdg-desktop-portal-openuri-$(VERSION).tar.gz xdg-desktop-portal-openuri-$(VERSION)

.PHONY: srpm
srpm: ## Builds the source RPM package
	make rpm-setup
	tar --transform 's/^build/xdg-desktop-portal-openuri/' -czf ./xdg-desktop-portal-openuri-$(VERSION).tar.gz -C . build
	rpmbuild --define "_topdir /tmp/rpmbuild" -bs /tmp/rpmbuild/SPECS/xdg-desktop-portal-openuri.spec
	mv /tmp/rpmbuild/SRPMS/xdg-desktop-portal-openuri-$(VERSION)-1.fc*.src.rpm .

.PHONY: rpm
rpm: ## Builds the binary RPM package
	make rpm-setup
	tar --transform 's/^build/xdg-desktop-portal-openuri/' -czf ./xdg-desktop-portal-openuri-$(VERSION).tar.gz -C . build
	rpmbuild --define "_topdir /tmp/rpmbuild" -bb /tmp/rpmbuild/SPECS/xdg-desktop-portal-openuri.spec
	mv /tmp/rpmbuild/RPMS/x86_64/xdg-desktop-portal-openuri-$(VERSION)-1.fc*.x86_64.rpm .

# Run the built binary from the build folder
.PHONY: run
run: build
	@if [ ! -f $(BUILD_DIR)/$(BINARY) ]; then \
		echo "Binary not found in build folder. Run 'make build' first."; \
		exit 1; \
	fi
	$(BUILD_DIR)/$(BINARY)

# Install dependencies on Fedora
.PHONY: deps
deps:
	dnf install -y gcc glib2-devel dbus-devel gtk3-devel xdg-utils cppcheck

# Clean up generated files
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

# Check build dependencies
.PHONY: check-build-deps
check-build-deps:
	@command -v gcc >/dev/null 2>&1 || { echo "gcc is required. Run 'make deps' to install dependencies."; exit 1; }
	@command -v pkg-config >/dev/null 2>&1 || { echo "pkg-config is required. Run 'make deps' to install dependencies."; exit 1; }
	@pkg-config --exists gio-2.0 glib-2.0 gtk+-3.0 || { echo "gio-2.0, glib-2.0, and gtk+-3.0 libraries are required. Run 'make deps' to install dependencies."; exit 1; }

# E.g. make in-docker TARGET=build
.PHONY: in-docker
in-docker:
	@# Check if the remote image is available
	@if ! docker pull $(IMAGE_NAME):$(IMAGE_TAG) >/dev/null 2>&1; then \
		echo "Remote image not found. Building locally..."; \
		docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .; \
	else \
		echo "Using remote image $(IMAGE_NAME):$(IMAGE_TAG)"; \
	fi

	@# Run the given make target inside Docker
	docker run --rm \
		-v $(shell pwd):/src:Z \
		--workdir /src \
		--user $(shell id -u):$(shell id -g) \
		-e DOTNET_CLI_HOME=/tmp \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		make $(TARGET)
