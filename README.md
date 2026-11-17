# prolog

A learning project following Travis Jeffery's
[*Distributed Services with Go*](https://www.oreilly.com/library/view/distributed-services-with/9781680508376/).
The project builds toward a distributed commit log, starting with an in-memory
HTTP prototype and adding storage, gRPC, security, and observability.

## Current state

- JSON/HTTP prototype backed by an in-memory slice.
- File-backed log with segments, protobuf records, and memory-mapped indexes.
- Unary and streaming gRPC operations, exercised by integration tests.
- Mutual TLS and client identity extracted from verified certificates.
- Zap request logging and OpenCensus metrics and traces.
- Casbin authorization wrapper and policy files; enforcement is not wired into
  the RPC handlers yet.

The executable still starts the HTTP prototype. The gRPC server is started by
the tests. Replication and cluster coordination are not implemented yet.

## Requirements

- Go 1.26.0 or newer, as specified in `go.mod`.
- `cfssl` and `cfssljson` on `PATH` for test certificates.
- `protoc`, `protoc-gen-go`, and `protoc-gen-go-grpc` on `PATH` when changing
  protobuf definitions. Generated Go files are checked in.
- `golangci-lint` v2 for the optional lint check.

## Setup and tests

Run from the repository root:

```bash
go mod download
make gencert
make test
```

`make gencert` generates a CA, a server certificate, and client certificates for
`root` and `nobody`. It moves them to `$HOME/.proglog/`. Each run replaces the
generated certificates and keys.

To use another directory, configure both the Makefile destination and the Go
configuration:

```bash
export CONFIG_DIR="$PWD/.local-config"
make gencert CONFIG_PATH="$CONFIG_DIR"
make test
```

`CONFIG_PATH` controls generation; `CONFIG_DIR` controls where Go loads files.
Keep locally generated certificates and keys out of commits.

`make test` runs `go test -race -v ./...`, including storage, authentication,
and TLS-backed gRPC tests. A `nobody` client certificate proves identity; denial
of its operations still requires authorization to be connected.

## Debugging observability

```bash
go test -race -v ./internal/server -run '^TestServer$' -count=1 -args -debug
```

This enables development logging and writes metrics and traces to temporary
files. The output prints paths such as `/tmp/metrics-123.log` and
`/tmp/traces-123.log`; open the paths from your run.

- **Logs:** RPC method, status, peer address, and `grpc.time_ns` duration.
- **Metrics:** request counts, latency, and message sizes.
- **Traces:** spans for individual RPCs, including duration and status.

The code samples every trace. The exporter is enabled only by the test flag;
the HTTP executable does not use this instrumentation.

## Run the HTTP prototype

```bash
make build
make run
```

It listens on `:5010`. `PORT` and `HOST` are declared in the Makefile but are
not connected to the executable. Records disappear when the process stops.

The `value` field is a byte slice, so JSON represents it as base64. For example,
`aGVsbG8=` encodes `hello`.

```bash
curl -X POST http://localhost:5010/ \
  -H 'Content-Type: application/json' \
  -d '{"record":{"value":"aGVsbG8="}}'
# {"offset":0}

curl -X GET http://localhost:5010/ \
  -H 'Content-Type: application/json' \
  -d '{"offset":0}'
# {"record":{"value":"aGVsbG8=","offset":0}}
```

## Storage and gRPC

The persistent log uses these layers:

| Layer | Responsibility |
|---|---|
| Log | Selects segments and assigns work to the active segment |
| Segment | Owns a range of offsets and a store/index pair |
| Store | Holds length-prefixed, protobuf-encoded records |
| Index | Maps relative offsets to byte positions in the store |

The store uses buffered writes; a successful append does not guarantee crash
durability.

The contract in `api/v1/log.proto` exposes:

| RPC | Behavior |
|---|---|
| `Produce` | Append one record and return its offset |
| `Consume` | Read one record at an offset |
| `ProduceStream` | Bidirectional stream of records and offsets |
| `ConsumeStream` | Read sequentially, waiting for new records |

## Project layout

```text
api/v1/          Protobuf definitions, generated code, and API errors
cmd/server/      HTTP entry point
internal/log/    Persistent storage
internal/server/ HTTP prototype, gRPC handlers, and integration tests
internal/config/ TLS configuration and file paths
internal/auth/   Casbin wrapper
test/            Certificate requests and authorization rules
```

## Development

```bash
make compile           # regenerate protobuf code
make lint              # go vet, then go fmt (modifies formatting)
golangci-lint run ./... # additional checks
make clean             # remove build artifacts
```
