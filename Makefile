BINARY_NAME ?= server
BUILD_DIR ?= .build
SERVER ?= $(BUILD_DIR)/$(BINARY_NAME)
PORT ?= 5010
HOST ?= localhost
GO ?= go

.PHONY: all build run clean test compile

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