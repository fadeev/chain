BINARY_NAME = blockchaind

# Set the VERSION variable to the latest Git tag or commit hash.
# If the repository has uncommitted changes, append '-dirty' to the version.
VERSION ?= $(shell git describe --tags --dirty --always 2>/dev/null || echo "unknown")

# Set the COMMIT variable to the short SHA-1 hash of the latest commit in the repository.
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Set the ldflags variable to pass version information to the Go linker.
# This includes the application name, version, and commit hash.
ldflags = -X github.com/cosmos/cosmos-sdk/version.Name=$(BINARY_NAME) \
	-X github.com/cosmos/cosmos-sdk/version.AppName=$(BINARY_NAME) \
	-X github.com/cosmos/cosmos-sdk/version.Version=$(VERSION) \
	-X github.com/cosmos/cosmos-sdk/version.Commit=$(COMMIT)

# Set the BUILD_FLAGS variable to pass the ldflags to the Go compiler.
BUILD_FLAGS := -ldflags '$(ldflags)'

all: proto-build install

# The 'install' target verifies the dependencies, then installs the application binary.
install:
	@echo "--> ensure dependencies have not been modified"
	@go mod verify
	@echo "--> installing the binary"
	@go build -o $(BINARY_NAME) ./cmd/node
	@mv $(BINARY_NAME) $$(go env GOPATH)/bin/

module:
	go run ../helpers/main.go

protoVer=0.11.6
protoImageName=ghcr.io/cosmos/proto-builder:$(protoVer)
protoImage=docker run --rm -v $(CURDIR):/workspace --workdir /workspace $(protoImageName)

proto-build:
	@echo "--> building proto files"
	@sh ./scripts/protocgen.sh

proto-all: proto-format proto-lint proto-gen

proto-gen:
	@echo "Generating Protobuf files"
	@$(protoImage) sh ./scripts/protocgen.sh

proto-swagger-gen:
	@echo "Generating Protobuf Swagger"
	@$(protoImage) sh ./scripts/protoc-swagger-gen.sh
	$(MAKE) update-swagger-docs

proto-format:
	@$(protoImage) find ./ -name "*.proto" -exec clang-format -i {} \;

proto-lint:
	@$(protoImage) buf lint --error-format=json

proto-check-breaking:
	@$(protoImage) buf breaking --against $(HTTPS_GIT)#branch=main

.PHONY: all install init module proto-all proto-gen proto-swagger-gen proto-format proto-lint proto-check-breaking