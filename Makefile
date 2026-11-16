BINARY_NAME ?= server
BUILD_DIR ?= .build
SERVER ?= $(BUILD_DIR)/$(BINARY_NAME)
PORT ?= 5010
HOST ?= localhost
GO ?= go
CONFIG_PATH=${HOME}/.proglog/

.PHONY: all build run clean test compile gencert

all: build

build: $(SERVER)

$(SERVER): $(shell find cmd internal -name '*.go') go.mod go.sum
	@$(GO) build -o $@ ./cmd/server

run: build
	$(SERVER)

clean:
	rm -rf $(BUILD_DIR)

test:
	$(GO) test -race -v ./...

compile:
	@protoc api/v1/*.proto --go_out=. --go-grpc_out=. --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative --proto_path=.

gencert:
	cfssl gencert \
		-initca test/ca-csr.json | cfssljson -bare ca
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=test/ca-config.json \
		-profile=server \
		test/server-csr.json | cfssljson -bare server
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=test/ca-config.json \
		-profile=client \
		test/client-csr.json | cfssljson -bare client
	mkdir -p "${CONFIG_PATH}"
	mv *.pem *.csr "${CONFIG_PATH}"
