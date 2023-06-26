This is a simple and partial implementation for a web server/framework.

This is how to initialize and start the server:
```
main :: proc() {
    server := http.init_server()
    http.add_route(&server, http.Verb.GET, "/books", get_books)

    http.start(&server);
}
```

Exposing views or files is done through by passing any of the `view` or `resource` method to `add_route` 
```
http.add_route(&server, http.Verb.GET, "/index", view)
http.add_route(&server, http.Verb.GET, "/something.css", resource)
```

**What's missing**

A lot of things, but mainly the implementation to handle concurrent requests
