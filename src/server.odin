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

get_http_version :: proc() -> Version {
    return .HTTP_1_1
}

add_route :: proc(server: ^Server, verb: Verb, path: string, action: invoke_endpoint) {
    route := Route{verb, path, action}
    append(&server.routes, route)
}

view :: proc(path: string) -> (c: []u8, sc: Status_Code) {
    p := path
    if path == "/" || path == "" {
        p = "index.html"
    }
    content, status_code := _load_resource(p)
    if status_code != .Ok {
        content, status_code = error_view(status_code)
    }
    return content, status_code
}

resource :: proc(path: string) -> (c: []u8, sc: Status_Code) {
    return _load_resource(path)
}

error_view :: proc(status_code: Status_Code) -> (c: []u8, sc: Status_Code) {
    path := get_error_path(status_code)
    return _load_resource(path)
}

@private
_load_resource :: proc(path: string) -> (c: []u8, sc: Status_Code) {
    sc = Status_Code.Ok
    content, status := _load_path(path); 
    if status != nil {
        if status == os.ERROR_FILE_NOT_FOUND {
            sc = .Not_Found
        } else {
            sc = .Internal_Server_Error
        }
    }
    return content, sc
}

@private
_load_path :: proc(path:string) -> (c: []u8, e: Maybe(os.Errno)) {
    path := []string{"./web/", path}
    file_name, _ := strings.concatenate(path)
    fd, err := os.open(file_name)
    if err != os.ERROR_NONE {
        return nil, err
    }
    defer os.close(fd)

    buffer: []u8
    _, err = os.read_full(fd, buffer)
    if err != os.ERROR_NONE {
        return nil, err
    }

    return buffer, nil
}

get_error_path :: proc(status_code: Status_Code) -> string {
    path: string
    #partial switch status_code {
        case .Not_Found: path = "not_found.html"
        case .Unauthorized: path = "unauthorized.html"
        case .Forbidden: path = "forbidden.html"
        case: path = "internal_server_error.html"
    }
    return path
}


invoke_endpoint :: #type proc(path: string) -> (content: []u8, status_code: Status_Code)

