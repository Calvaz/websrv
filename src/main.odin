package http

import "core:fmt"

main :: proc() {
    fmt.println("Starting web server...")
    
    server := init_server()
    start(server)
    //add_route()
    //start()
}


