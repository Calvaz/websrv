package http

import "core:strings"

@private
process_request :: proc(routes: map[Route]Callback, request_buffer: []u8) -> (builder: Request_Builder, err: Maybe(Http_Parsing_Error)) {
    token := make([dynamic]u8, 0, 3)
    request: Request_Builder
    defer delete(token)

    tokens: u8 = 0
    for b in request_buffer {
        if tokens == 3 {
            break
        }

        if b == byte(' ') || b == byte('\r') {
            parse_request_type(&request, routes, string(token[:]), tokens) or_return
            tokens += 1
            token = make([dynamic]u8, 0, 3)
            continue
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

@private
parse_request_type :: proc(request: ^Request_Builder, routes: map[Route]Callback, token: string, tokens: u8) -> Maybe(Http_Parsing_Error) {
    err: Maybe(Http_Parsing_Error)
    switch tokens {
    case 0: err = parse_verb(request, token)
    case 1: err = parse_page(request, routes, token)
    case 2: err = parse_http_version(request, token)
    }
    return err
}

@private
parse_headers :: proc(request: ^Request_Builder, token: string, tokens: u8) {
    // to implement
}

@private
parse_verb :: proc(request: ^Request_Builder, token: string) -> Maybe(Http_Parsing_Error) {
    switch token {
    case "GET": request.method = Verb.GET
    case "POST": request.method = Verb.POST
    case "PUT": request.method = Verb.PUT
    case "PATCH": request.method = Verb.PATCH
    case "DELETE": request.method = Verb.DELETE
    case "OPTIONS": request.method = Verb.OPTIONS
    case "TRACE": request.method = Verb.TRACE
    case "CONNECT": request.method = Verb.CONNECT
    case "HEAD": request.method = Verb.HEAD
    case: return Http_Parsing_Error.Bad_Http_Verb
    }
    return nil
}

@private
parse_page :: proc(request: ^Request_Builder, routes: map[Route]Callback, token: string) -> Maybe(Http_Parsing_Error) {
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

    if len(routes) == 0 {
        return .Bad_Http_Page
    }

    route: Maybe(Route)
    for r in routes {
        if r.verb == request.method && r.endpoint == path {
            route = r
        }
    }

    if r, has_value := route.?; !has_value {
        return .Bad_Http_Page
    }

    request.route = route.?

    return nil
}

@private
parse_http_version :: proc(request: ^Request_Builder, token: string) -> Maybe(Http_Parsing_Error) {
    err: Maybe(Http_Parsing_Error) = nil
    switch token {
    case "HTTP/1.1": request.version = .HTTP_1_1
    case "HTTP/2.0": request.version = .HTTP_2_0
    case: err = Http_Parsing_Error.Bad_Http_Version
    }
    return err
}

@private
handle_error_response :: proc(err: Http_Parsing_Error) -> Status_Code {
    status_code: Status_Code
    if err == .Bad_Http_Page {
        status_code = .Not_Found
    } else {
        status_code = .Internal_Server_Error
    }

    return status_code
}

@private
get_sc_message :: proc(sc: Status_Code) -> string {
    res: string
    switch sc {
    case .Continue: res = "CONTINUE"
    case .Switching_Protocols: res = "SWITCHING_PROTOCOLS"
    case .Early_Hints: res = "EARLY_HINTS"
    case .Ok: res = "OK"
    case .Created: res = "CREATED"
    case .Accepted: res = "ACCEPTED"
    case .Non_Authoritative_Information: res = "NON_AUTHORITATIVE_INFORMATION"
    case .No_Content: res = "NO_CONTENT"
    case .Reset_Content: res = "RESET_CONTENT"
    case .Partial_Content: res = "PARTIAL_CONTENT"
    case .Multiple_Choices: res = "MULTIPLE_CHOICES"
    case .Moved_Permanently: res = "MOVED_PERMANENTLY"
    case .Found: res = "FOUND"
    case .Not_Modified: res = "NOT_MODIFIED"
    case .Bad_Request: res = "BAD_REQUEST"
    case .Unauthorized: res = "UNAUTHORIZED"
    case .Forbidden: res = "FORBIDDEN"
    case .Not_Found: res = "NOT_FOUND"
    case .Method_Not_Allowed: res = "METHOD_NOT_ALLOWED"
    case .Request_Timeout: res = "REQUEST_TIMEOUT"
    case .Im_A_Teapot: res = "IM_A_TEAPOT"
    case .Internal_Server_Error: res = "INTERNAL_SERVER_ERROR"
    case .Not_Implemented: res = "NOT_IMPLEMENTED"
    case .Bad_Gateway: res = "BAD_GATEWAY"
    case .Service_Unvailable: res = "SERVICE_UNVAILABLE"
    case .Gateway_Timeout: res = "GATEWAY_TIMEOUT"
    case .Http_Version_Not_Supported: res = "HTTP_VERSION_NOT_SUPPORTED"
    }
    return res
}

@private
get_http_version :: proc(v: Version) -> string {
    res: string
    switch v {
    case .HTTP_1_1: res = "HTTP/1.1"
    case .HTTP_2_0: res = "HTTP/2.0"
    }
    return res
}

@private
get_mime_type :: proc(ext: string) -> string {
    res: string
    switch ext {
    case "ico": res = "image/ico"
    case "png": res = "image/png"
    case "jpg": res = "image/jpg"
    case "gif": res = "image/gif"
    case "bmp": res = "image/bmp"
    case "html": res = "text/html"
    case "css": res = "text/css"
    case "js": res = "text/javascript"
    case: res = "text/html"
    }
    return res
}

