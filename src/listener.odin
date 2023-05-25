package http

import "core:fmt"
import "core:net"
import "core:strings"
import "core:bytes"

// Initialize the listener on the defined ports
listen_and_serve :: proc(server: ^Server) -> Maybe(net.Network_Error) {
    socket := net.listen_tcp(server.hostname_and_port) or_return

    for ;; {

        fmt.printf("Listening on incoming requests at %v:%v\n", host, port)
        client, _ := net.accept_tcp(socket) or_return
        defer net.close(client)

        read_buf := [4096]u8{} 
        if _, err := net.recv_tcp(client, read_buf[:]); err != nil {
            fmt.println("received error on receive")
            return err
        }

        fmt.printf("requesting: %v \n", string(read_buf[:]))
        
        response: []u8
        sc: Status_Code
        request_builder, err := process_request(server.routes, read_buf[:]);
        if err.(Http_Parsing_Error) != nil {
            if err == Http_Parsing_Error.Bad_Http_Page {
                response, sc = error_view(Status_Code.Not_Found)

            } else {
                sc = handle_error_response(err.?)
            }

        } else {
            response, sc = request_builder.Route.Action(request_builder.Route.Endpoint)
        }

        if _, err := net.send_tcp(client, response[:]); err != nil {
            fmt.println(err)
            return err
        }
    }

    return nil
}

process_request :: proc(routes: [dynamic]Route, request_buffer: []u8) -> (builder: Request_Builder, err: Maybe(Http_Parsing_Error)) {
    token : [dynamic]u8
    request: Request_Builder

    tokens: u8 = 0
    for b in request_buffer {
        if b == byte(' ') || b == byte('\r') {
            parse_request_type(&request, routes, string(token[:]), tokens) or_return
            tokens += 1
        }

        if tokens == 2 {
            break
        }
        append(&token, b)
    }

    for b in request_buffer[len(token):] {
        if b == byte(' ') || b == byte('\r') {
            parse_headers(&request, string(token[:]), tokens)
            tokens += 1
        }
    }

    return request, nil
}

parse_request_type :: proc(request: ^Request_Builder, routes: [dynamic]Route, token: string, tokens: u8) -> Maybe(Http_Parsing_Error) {
    err: Maybe(Http_Parsing_Error)
    switch tokens {
    case 0: err = parse_verb(request, token)
    case 1: err = parse_page(request, routes, token)
    case 2: err = parse_http_version(request, token)
    }
    return err
}

parse_headers :: proc(request: ^Request_Builder, token: string, tokens: u8) {
    
}

parse_verb :: proc(request: ^Request_Builder, token: string) -> Maybe(Http_Parsing_Error) {
    switch token {
    case "GET": request.Method = Verb.GET
    case "POST": request.Method = Verb.POST
    case "PUT": request.Method = Verb.PUT
    case "PATCH": request.Method = Verb.PATCH
    case "DELETE": request.Method = Verb.DELETE
    case "OPTIONS": request.Method = Verb.OPTIONS
    case "TRACE": request.Method = Verb.TRACE
    case "CONNECT": request.Method = Verb.CONNECT
    case "HEAD": request.Method = Verb.HEAD
    case: return Http_Parsing_Error.Bad_Http_Verb
    }
    return nil
}

parse_page :: proc(request: ^Request_Builder, routes: [dynamic]Route, token: string) -> Maybe(Http_Parsing_Error) {
    path: string
    params: string
    if strings.contains(token, "?") {
        route: []string
        if route, err := strings.split_after(token, "?"); err != nil {
            return .Internal_Error
        }
        path = route[0]
        params = route[1]
    } else {
        path = token
    }

    route: Route
    for r in routes {
        if r.Verb == request.Method && r.Endpoint == path {
            route = r
        }
    }

    if &route == nil {
        return .Bad_Http_Page
    }
    request.Route = route

    return nil
}

parse_http_version :: proc(request: ^Request_Builder, token: string) -> Maybe(Http_Parsing_Error) {
    switch token {
    case "HTTP/1.1": request.Version = Version.HTTP_1_1
    case "HTTP/2.0": request.Version = Version.HTTP_2_0
    case: return Http_Parsing_Error.Bad_Http_Version
    }
    return nil
}

handle_error_response :: proc(err: Http_Parsing_Error) -> Status_Code {
    status_code: Status_Code
    if err == .Bad_Http_Page {
        status_code = .Not_Found
    } else {
        status_code = .Internal_Server_Error
    }

    return status_code
}

