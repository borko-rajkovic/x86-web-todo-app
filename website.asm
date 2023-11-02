format ELF64 executable

include "linux.inc"

MAX_CONN equ 5
REQUEST_CAP equ 128*1024

segment readable executable

include "utils.inc"

entry main
main:
    funcall2 write_cstr, STDOUT, start

    funcall2 write_cstr, STDOUT, socket_trace_msg

    ; Opening socket
    socket AF_INET, SOCK_STREAM, 0
    cmp rax, 0
    jl .fatal_error
    mov qword [sockfd], rax

    setsockopt [sockfd], SOL_SOCKET, SO_REUSEADDR, enable, 4
    cmp rax, 0
    jl .fatal_error

    setsockopt [sockfd], SOL_SOCKET, SO_REUSEPORT, enable, 4
    cmp rax, 0
    jl .fatal_error

    ; Binding socket
    ; Implementing the same way as TCP server in C, just check here:
    ; https://www.geeksforgeeks.org/tcp-server-client-implementation-in-c/

    funcall2 write_cstr, STDOUT, bind_trace_msg
    ; Preparing structure
    mov word [servaddr.sin_family], AF_INET
    mov dword [servaddr.sin_port], 14619 ; port 6969 in reverse order (check htons.py)
    mov dword [servaddr.sin_addr], INADDR_ANY

    ; Calling bind method
    ; bind(sockfd, (SA*)&servaddr, sizeof(servaddr))
    ; Notes:
    ;   servaddr.sin_family -   points to the first field in the structure,
    ;                           so we can say it's the pointer to structure itself
    bind [sockfd], servaddr.sin_family, sizeof_servaddr
    cmp rax, 0
    jl .fatal_error

    funcall2 write_cstr, STDOUT, listen_trace_msg
    listen [sockfd], MAX_CONN
    cmp rax, 0
    jl .fatal_error

.next_request:
    funcall2 write_cstr, STDOUT, accept_trace_msg
    accept [sockfd], cliaddr.sin_family, cliaddr_len
    cmp rax, 0
    jl .fatal_error

    mov qword [connfd], rax

    ; int3 - uncomment for software interrupt

    read [connfd], request, REQUEST_CAP
    cmp rax, 0
    jl .fatal_error
    mov [request_len], rax

    mov [request_cur], request

    write STDOUT, [request_cur], [request_len]

    funcall4 starts_with, [request_cur], [request_len], get, get_len
    cmp rax, 0
    jg .handle_get_method

    funcall4 starts_with, [request_cur], [request_len], post, post_len
    cmp rax, 0
    jg .handle_post_method

    jmp .serve_error_405

.handle_get_method:
    add [request_cur], get_len
    sub [request_len], get_len

    funcall4 starts_with, [request_cur], [request_len], index_route, index_route_len
    cmp rax, 0
    jg .serve_index_page

    jmp .serve_error_404

.handle_post_method:
    add [request_cur], post_len
    sub [request_len], post_len

    funcall4 starts_with, [request_cur], [request_len], index_route, index_route_len
    cmp rax, 0
    jg .process_add_or_delete_todo_post

    funcall4 starts_with, [request_cur], [request_len], shutdown_route, shutdown_route_len
    cmp rax, 0
    jg .process_shutdown

    jmp .serve_error_404

.process_shutdown:
    funcall2 write_cstr, [connfd], shutdown_response
    jmp .shutdown

.process_add_or_delete_todo_post:
    call drop_http_header
    cmp rax, 0
    je .serve_error_400

    funcall2 write_cstr, STDOUT, new_line
    funcall2 write_cstr, STDOUT, executing_command_msg
    write STDOUT, [request_cur], [request_len]

    funcall4 starts_with, [request_cur], [request_len], todo_form_data_prefix, todo_form_data_prefix_len
    cmp rax, 0
    jg .add_new_todo_and_serve_index_page

    funcall4 starts_with, [request_cur], [request_len], delete_form_data_prefix, delete_form_data_prefix_len
    cmp rax, 0
    jg .delete_todo_and_serve_index_page

    jmp .serve_error_400

.serve_index_page:
    funcall2 write_cstr, [connfd], index_page_response
    funcall2 write_cstr, [connfd], index_page_header
    funcall2 write_cstr, [connfd], index_page_footer
    close [connfd]
    jmp .next_request

.serve_error_400:
    funcall2 write_cstr, [connfd], error_400
    close [connfd]
    jmp .next_request

.serve_error_404:
    funcall2 write_cstr, [connfd], error_404
    close [connfd]
    jmp .next_request

.serve_error_405:
    funcall2 write_cstr, [connfd], error_405
    close [connfd]
    jmp .next_request

.add_new_todo_and_serve_index_page:
    add [request_cur], todo_form_data_prefix_len
    sub [request_len], todo_form_data_prefix_len

    ; here we should add new todo
    jmp .serve_index_page

.delete_todo_and_serve_index_page:
    add [request_cur], delete_form_data_prefix_len
    sub [request_len], delete_form_data_prefix_len

    funcall2 parse_uint, [request_cur], [request_len]
    ; here we should delete a todo - rdi is parsed id
    jmp .serve_index_page

.shutdown:
    funcall2 write_cstr, STDOUT, ok_msg
    close [connfd]
    close [sockfd]
    exit EXIT_SUCCESS

.fatal_error:
    funcall2 write_cstr, STDERR, error_msg
    close [connfd]
    close [sockfd]
    exit EXIT_FAILURE

drop_http_header:
.next_line:
    funcall4 starts_with, [request_cur], [request_len], crlf, 2
    cmp rax, 0
    jg .reached_end

    funcall3 find_char, [request_cur], [request_len], 10
    cmp rax, 0
    je .invalid_header

    mov rsi, rax
    sub rsi, [request_cur]
    inc rsi
    add [request_cur], rsi
    sub [request_len], rsi

    jmp .next_line

.reached_end:
    add [request_cur], 2
    sub [request_len], 2
    mov rax, 1
    ret

.invalid_header:
    xor rax, rax
    ret


segment readable writeable

enable dd 1
sockfd dq -1
connfd dq -1
servaddr servaddr_in
sizeof_servaddr = $ - servaddr.sin_family
cliaddr servaddr_in
cliaddr_len dd sizeof_servaddr

crlf db 13, 10

error_400            db "HTTP/1.1 400 Bad Request", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db "<h1>Bad Request</h1>", 10
                     db "<a href='/'>Back to Home</a>", 10
                     db 0
error_404            db "HTTP/1.1 404 Not found", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db "<h1>Page not found</h1>", 10
                     db "<a href='/'>Back to Home</a>", 10
                     db 0
error_405            db "HTTP/1.1 405 Method Not Allowed", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db "<h1>Method not Allowed</h1>", 10
                     db "<a href='/'>Back to Home</a>", 10
                     db 0
index_page_response  db "HTTP/1.1 200 OK", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db 0
index_page_header    db "<h1>To-Do</h1>", 10
                     db "<ul>", 10
                     db 0
index_page_footer    db "  <li>", 10
                     db "    <form style='display: inline' method='post' action='/' enctype='text/plain'>", 10
                     db "        <input style='width: 25px' type='submit' value='+'>", 10
                     db "        <input type='text' name='todo' autofocus>", 10
                     db "    </form>", 10
                     db "  </li>", 10
                     db "</ul>", 10
                     db 0
shutdown_response    db "HTTP/1.1 200 OK", 13, 10
                     db "Content-Type: text/html; charset=utf-8", 13, 10
                     db "Connection: close", 13, 10
                     db 13, 10
                     db "<h1>Shutting down the server...</h1>", 10
                     db "Please close this tab"
                     db 0

todo_form_data_prefix db "todo="
todo_form_data_prefix_len = $ - todo_form_data_prefix
delete_form_data_prefix db "delete="
delete_form_data_prefix_len = $ - delete_form_data_prefix

get db "GET "
get_len = $ - get
post db "POST "
post_len = $ - post

index_route db "/ "
index_route_len = $ - index_route

shutdown_route db "/shutdown "
shutdown_route_len = $ - shutdown_route

new_line                db 10, 0
start                   db "INFO: Starting Web Server!", 10, 0
ok_msg                  db "INFO: OK!", 10, 0
socket_trace_msg        db "INFO: Creating a socket...", 10, 0
bind_trace_msg          db "INFO: Binding the socket...", 10, 0
listen_trace_msg        db "INFO: Listening to the socket...", 10, 0
accept_trace_msg        db "INFO: Waiting for client connections...", 10, 0
executing_command_msg   db "INFO: Executing command: ", 0
error_msg               db "FATAL ERROR!", 10, 0

request_len rq 1
request_cur rq 1
request     rb REQUEST_CAP
