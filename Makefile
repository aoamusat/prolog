BINARY_NAME ?= server
BUILD_DIR ?= .build
SERVER ?= $(BUILD_DIR)/$(BINARY_NAME)
PORT ?= 5010
HOST ?= localhost
GO ?= go
CONFIG_PATH=${HOME}/.proglog/

.PHONY: all build run clean test compile gencert lint

all: build

build: $(SERVER)

$(CONFIG_PATH)/model.conf:
	cp test/model.conf $(CONFIG_PATH)/model.conf
$(CONFIG_PATH)/policy.csv:
	cp test/policy.csv $(CONFIG_PATH)/policy.csv

$(SERVER): $(shell find cmd internal -name '*.go') go.mod go.sum
	@$(GO) build -o $@ ./cmd/server

run: build
	$(SERVER)
lint:
	$(GO) vet ./...
	$(GO) fmt ./...
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
		-cn="root" \
		test/client-csr.json | cfssljson -bare root-client
	cfssl gencert \
		-ca=ca.pem \
		-ca-key=ca-key.pem \
		-config=test/ca-config.json \
		-profile=client \
		-cn="nobody" \
		test/client-csr.json | cfssljson -bare nobody-client
	mkdir -p "${CONFIG_PATH}"
	mv *.pem *.csr "${CONFIG_PATH}"
