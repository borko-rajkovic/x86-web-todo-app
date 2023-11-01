format ELF64 executable

include "linux.inc"

MAX_CONN equ 5

segment readable executable

include "utils.inc"

entry main
main:
    funcall2 write_cstr, STDOUT, start

    funcall2 write_cstr, STDOUT, socket_trace_msg

    ; Opening socket
    socket AF_INET, SOCK_STREAM, 0
    cmp rax, 0
    jl error
    mov qword [sockfd], rax

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
    jl error

    funcall2 write_cstr, STDOUT, listen_trace_msg
    listen [sockfd], MAX_CONN
    cmp rax, 0
    jl error

next_request:
    funcall2 write_cstr, STDOUT, accept_trace_msg
    accept [sockfd], cliaddr.sin_family, cliaddr_len
    cmp rax, 0
    jl error

    mov qword [connfd], rax

    write [connfd], response, response_len
    close [connfd]

    jmp next_request

    funcall2 write_cstr, STDOUT, ok_msg
    close [sockfd]
    exit EXIT_SUCCESS

error:
    funcall2 write_cstr, STDERR, error_msg
    close [connfd]
    close [sockfd]
    exit EXIT_FAILURE


segment readable writeable

sockfd dq -1
connfd dq -1
servaddr servaddr_in
sizeof_servaddr = $ - servaddr.sin_family
cliaddr servaddr_in
cliaddr_len dd sizeof_servaddr

hello db "Hello from the flat assembler", 10

response    db "HTTP/1.1 200 OK", 13, 10 ; instead of newline, we print both cr and nl: 13 = \r 10 = \n
            db "Content-Type: text/html; charset=utf-8", 13, 10
            db "Connection: close", 13, 10
            db 13, 10
            db "<h1>Hello from the flat assembler</h1>", 13, 10
response_len = $ - response

start            db "INFO: Starting Web Server!", 10, 0
ok_msg           db "INFO: OK!", 10, 0
socket_trace_msg db "INFO: Creating a socket...", 10, 0
bind_trace_msg   db "INFO: Binding the socket...", 10, 0
listen_trace_msg db "INFO: Listening to the socket...", 10, 0
accept_trace_msg db "INFO: Waiting for client connections...", 10, 0
error_msg        db "FATAL ERROR!", 10, 0

