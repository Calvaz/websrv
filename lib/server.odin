package http

import "core:fmt"
import "core:net"
import "core:strings"
import "core:os"
import "core:slice"

@private
Server :: struct {
    host: net.IP4_Address,
    port: int,
    routes: map[Route]Callback,
}

host:net.IP4_Address : {0, 0, 0, 0} 
port:int : 8080

space :: " "
new_line :: "\r\n"

init_server :: proc(hostname: net.IP4_Address = host, port: int = port) -> Server {
    server := Server{}
    server.host = hostname
    server.port = port
    add_route(&server, .GET, "/", view)
    add_route(&server, .GET, "/index", view)
    return server
}

start :: proc(server: ^Server) -> Maybe(net.Network_Error) {
    fmt.println("Starting web server...")
    if err := listen_and_serve(server); err != nil {
        fmt.printf("%v", err)
    }

    return nil
}

// Initialize the listener on the defined ports
listen_and_serve :: proc(server: ^Server) -> Maybe(net.Network_Error) {
    socket := net.listen_tcp({server.host, server.port}) or_return

    for {

        fmt.printf("Listening on incoming requests at %v:%v\n", server.host, server.port)
        client, _ := net.accept_tcp(socket) or_return
        defer net.close(client)

        read_buf := [4096]u8{} 
        if _, err := net.recv_tcp(client, read_buf[:]); err != nil {
            fmt.printf("Error on receiving packet: %v", err)
            return err
        }

        fmt.printf("Requesting: %v \n", string(read_buf[:]))
        
        action_res: Result
        request_builder, err := process_request(server.routes, read_buf[:]);
        if err_value, is_err := err.?; is_err {
            action_res.status_code = handle_error_response(err_value)
        } else {
            action_res = server.routes[request_builder.route](&request_builder)
        }
    
        response := _build_response(&request_builder, action_res.content, action_res.status_code)
        if _, err := net.send_tcp(client, response[:]); err != nil {
            fmt.printf("Could not send tcp response because: %s", err)
            return err
        }
    }

    return nil
}

@private
_build_response :: proc(request_builder: ^Request_Builder, content: []u8, sc: Status_Code) -> []u8 {
    response := Response_Builder{}
    response.version = request_builder.version
    response.status_code = sc
    response.sc_message = get_sc_message(sc)
    ext := strings.split(request_builder.route.endpoint, ".")
    response.extension = ext[0]
    if len(ext) > 1 {
        response.extension = ext[1]
    }

    response.content = content

    resp := _to_byte_array(&response)
    return resp
}

@private
_to_byte_array :: proc(builder: ^Response_Builder) -> []u8 {
    response := []string{
        get_http_version(builder.version), space, fmt.tprint(int(builder.status_code)), space, builder.sc_message, new_line,
        
        //headers
        "Server:", space, "Hello", new_line,
        "Content-Length:", space, fmt.tprint(len(builder.content)), new_line,
        "Content-Type:", space, get_mime_type(builder.extension), "\n",
        
        //content
        "\n", string(builder.content)} //clearly not the best solution here
    response_text := strings.concatenate(response)
    response_buffer := transmute([]u8)response_text
    return response_buffer
}

