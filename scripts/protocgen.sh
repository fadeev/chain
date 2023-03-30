#!/usr/bin/env bash

set -eo pipefail

go install github.com/grpc-ecosystem/grpc-gateway/protoc-gen-grpc-gateway@latest
go install github.com/cosmos/gogoproto/proto
go install github.com/cosmos/gogoproto/gogoproto
go install github.com/cosmos/gogoproto/jsonpb
go install github.com/cosmos/gogoproto/protoc-gen-gogo
go install github.com/cosmos/gogoproto/protoc-gen-gofast
go install github.com/cosmos/gogoproto/protoc-gen-gogofast
go install github.com/cosmos/gogoproto/protoc-gen-gogofaster
go install github.com/cosmos/gogoproto/protoc-gen-gogoslick
go install github.com/cosmos/gogoproto/protoc-gen-gostring
go install github.com/cosmos/gogoproto/protoc-gen-gogotypes
go install github.com/cosmos/gogoproto/protoc-min-version
go install github.com/cosmos/gogoproto/protoc-gen-combo
go install github.com/cosmos/gogoproto/protoc-gen-gocosmos
go install github.com/cosmos/gogoproto/gogoreplace

go install github.com/cosmos/cosmos-proto/cmd/protoc-gen-go-pulsar@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Define a shell function for generating proto code.
generate_proto() {
  local dir="$1"
  for file in "$dir"/*.proto; do
    if grep -q go_package "$file"; then
      if command -v buf >/dev/null 2>&1; then
        buf generate --template buf.gen.gogo.yaml "$file"
      else
        echo "Error: buf command not found. See https://docs.buf.build/installation" >&2
        exit 1
      fi
    fi
  done
}

# Generate Gogo proto code.
cd proto
buf mod update
proto_dirs=$(find . -path -prune -o -name '*.proto' -print0 | xargs -0 -n1 dirname | sort | uniq)
if [ -z "$proto_dirs" ]; then
  exit 0
else
  for dir in $proto_dirs; do
    generate_proto "$dir"
  done
fi
cd ..

# Move proto files to the right places.
if [ -d "blockchain" ]; then
  cp -r blockchain/* ./
  rm -rf blockchain
fi
rm -rf api

(cd proto; buf generate --template buf.gen.pulsar.yaml)