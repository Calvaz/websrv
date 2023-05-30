package http

import "core:os"
import "core:fmt"
import "core:strings"
import "core:intrinsics"

Route :: struct {
    verb: Verb,
    endpoint: string,
}

Result :: struct {
    content: []u8, 
    status_code: Status_Code,
}

Callback :: proc(req: ^Request_Builder) -> Result

add_route :: proc(server: ^Server, verb: Verb, path: string, action: Callback) {
    server.routes[Route{verb, path}] = action
}

view :: proc(req: ^Request_Builder) -> Result {
    path := req.route.endpoint

    if path == "/" || path == "/index" {
        path = "index.html"
    }
    res := _load_resource(path)
    if res.status_code != .Ok {
        res = error_view(res.status_code)
    }
    return { res.content, res.status_code }
}

resource :: proc(req: ^Request_Builder) -> Result {
    return _load_resource(req.route.endpoint)
}

error_view :: proc(status_code: Status_Code) -> Result {
    path := get_error_path(status_code)
    return _load_resource(path)
}

@private
_load_resource :: proc(path: string) -> Result {
    sc := Status_Code.Ok
    content, status := _load_path(path); 
    if status != nil {
        fmt.printf("os error number: %v", status)
        if status == os.ERROR_FILE_NOT_FOUND || status == os.ERROR_PATH_NOT_FOUND {
            sc = .Not_Found
        } else {
            sc = .Internal_Server_Error
        }
    }
    return { content, sc }
}

@private
_load_path :: proc(path:string) -> (c: []u8, e: Maybe(os.Errno)) {
    current_dir := os.get_current_directory()
    path := []string{current_dir, "\\lib\\web\\pages\\", path}
    file_name, _ := strings.concatenate(path)

    fd, err := os.open(file_name)
    if err != os.ERROR_NONE {
        return nil, err
    }
    defer os.close(fd)

	length: i64
	if length, err = os.file_size(fd); err != os.ERROR_NONE {
	    return nil, err
	}

	if length <= 0 {
		return nil, os.ERROR_INSUFFICIENT_BUFFER
	}

    data := make([]byte, int(length))
	if data == nil {
	    return nil, os.ERROR_INSUFFICIENT_BUFFER
	}

	bytes_read, read_err := os.read_full(fd, data)
	if read_err != os.ERROR_NONE {
		delete(data)
		return nil, read_err
	}
	return data[:bytes_read], nil
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

