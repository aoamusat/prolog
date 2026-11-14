package main

import (
	"log"

	"a4m.dev/prolog/internal/server"
)

func main() {
	server := server.NewHTTPServer(":5010")
	log.Fatal(server.ListenAndServe())
}
