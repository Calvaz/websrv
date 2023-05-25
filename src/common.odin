package http

import "core:net"

Request_Builder :: struct {
    Version: Version,
    Method: Verb,
    Headers: map[Request_Header]string,
    Route: Route,
}

ResponseBuilder :: struct {
    Version: Version,
    Method: Verb,
    Status_Code: Status_Code,
    Headers: map[Response_Header]string,
    Content_Length: u64,
    Content: []u8,
}

Version :: enum {
    HTTP_1_1 = 11,   
    HTTP_2_0 = 20, // not implemented
}

Verb :: enum {
    GET,   
    HEAD,   
    POST,   
    PUT,   
    DELETE,   
    CONNECT,   
    OPTIONS,   
    TRACE,   
    PATCH,
}

Status_Code :: enum {
    Continue = 100,   
    Switching_Protocols = 101,   
    Early_Hints = 103,   
    Ok = 200,   
    Created = 201,   
    Accepted = 202,   
    Non_Authoritative_Information = 203,   
    No_Content = 204,   
    Reset_Content = 205,   
    Partial_Content = 206,   
    Multiple_Choices = 300,   
    Moved_Permanently = 301,   
    Found = 302,   
    Not_Modified = 304,   
    Bad_Request = 400,   
    Unauthorized = 401,   
    Forbidden = 403,   
    Not_Found = 404,   
    Method_Not_Allowed = 405,   
    Request_Timeout = 408,   
    Im_A_Teapot = 418,   
    Internal_Server_Error = 500,   
    Not_Implemented = 501,   
    Bad_Gateway = 502,   
    Service_Unvailable = 503,   
    Gateway_Timeout = 504,   
    Http_Version_Not_Supported = 505,
}

Request_Header :: enum {
    
}

Response_Header :: enum {
    Content_Length,
}

Http_Parsing_Error :: enum {
    Bad_Http_Version,
    Bad_Http_Verb,
    Bad_Http_Page,
    Internal_Error,
}

