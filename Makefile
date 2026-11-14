BINARY_NAME ?= server
BUILD_DIR ?= .build
SERVER ?= $(BUILD_DIR)/$(BINARY_NAME)
PORT ?= 5010
HOST ?= localhost
GO ?= go

.PHONY: all build run clean test

all: build

build: $(SERVER)

$(SERVER): $(shell find cmd internal -name '*.go') go.mod go.sum
	@$(GO) build -o $@ ./cmd/server

run: build
	$(SERVER)

clean:
	rm -rf $(BUILD_DIR)

test:
	$(GO) test ./...
