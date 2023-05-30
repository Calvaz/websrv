package main

import "core:fmt"
import http "/lib"

main :: proc() {
    server := http.init_server()
    http.add_route(&server, http.Verb.GET, "/books", get_books)

    http.start(&server);
}

