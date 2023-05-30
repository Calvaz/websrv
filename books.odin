package main

import http "/lib"
import "core:fmt"

Book :: struct {
    name: string,
    pages: u16,
}

get_books :: proc(req: ^http.Request_Builder) -> http.Result {
    books := []Book{ Book{"pippo", 200}, Book{"pluto", 300}}
    return { transmute([]u8)fmt.tprintf("%s", books), .Ok }
}

