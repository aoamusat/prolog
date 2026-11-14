# prolog

A distributed commit log service implemented in Go, following the book
*Distributed Services with Go* (O'Reilly).

## API

The server exposes a single endpoint serving both produce and consume:

### Produce a record

```
POST /
Content-Type: application/json

{"record": {"value": "hello"}}
```

Response:

```
{"offset": 0}
```

### Consume a record

```
GET /
Content-Type: application/json

{"offset": 0}
```

Response:

```
{"record": {"value": "hello", "offset": 0}}
```

## Build and run

```bash
make build
make run
```

The server listens on `:5010` by default. Override with `PORT`/`HOST`:

```bash
make run PORT=8080 HOST=0.0.0.0
```

## Development

```bash
make test      # run tests
make clean     # remove build artifacts
```

## Requirements

- Go 1.25+
- `github.com/gorilla/mux` (managed via `go.mod`)
