package http

import "core:fmt"
import "core:net"
import "core:strings"
import "core:os"

@private
Server :: struct {
    hostname_and_port: net.Endpoint,
    routes: [dynamic]Route,
}

Route :: struct {
    Verb: Verb,
    Endpoint: string,
    Action: invoke_endpoint,
}

host:net.IP4_Address : {0, 0, 0, 0} 
port:int : 8080

init_server :: proc(hostname: net.IP4_Address = host, port: int = port) -> ^Server {
    server := Server{net.Endpoint{hostname, port}, make([dynamic]Route)}
    return &server
}

start :: proc(server: ^Server) -> Maybe(net.Network_Error) {
    if err := listen_and_serve(server); err != nil {
        fmt.printf("%v", err)
    }
    return nil
}

respond :: proc(status_code: Status_Code, content: string) -> []u8 {
    version := get_http_version()
    //content := "<html><head><meta http-equiv='content-type' content='text/html; charset=utf-8'/>\n</head>Hello Browser!</html>"
    return []u8{}
}

get_http_version :: proc() -> Version {
    return .HTTP_1_1
}

add_route :: proc(server: ^Server, verb: Verb, path: string, action: invoke_endpoint) {
    route := Route{verb, path, action}
    append(&server.routes, route)
}

view :: proc(path: string) -> (content: []u8, status_code: Status_Code) {
    return nil, nil
}

resource :: proc(path: string) -> (content: []u8, status_code: Status_Code) {
    extension: string
    if extension, err := strings.split(path, "."); err != nil {
        fmt.println(err)
        return nil, .Not_Found
    }

    if extension == "" {
        extension = "html"
    }

    path := []string{"./web/", path, ".", extension}
    file, _ := strings.concatenate(path)
    web, _ := os.open(file)

    return nil, nil
}

invoke_endpoint :: #type proc(path: string) -> (content: []u8, status_code: Status_Code)

