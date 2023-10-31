format ELF64 executable

SYS_write equ 1
SYS_close equ 3
SYS_socket equ 41
SYS_bind equ 49
SYS_accept equ 43
SYS_listen equ 50
SYS_exit equ 60

AF_INET equ 2
INADDR_ANY equ 0
SOCK_STREAM equ 1

STDOUT equ 1
STDERR equ 2

EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

MAX_CONN equ 5

macro syscall1 number, a
{
    mov rax, number
    mov rdi, a
    syscall
}

macro syscall2 number, a, b
{
    mov rax, number
    mov rdi, a
    mov rsi, b
    syscall
}

macro syscall3 number, a, b, c
{
    mov rax, number
    mov rdi, a
    mov rsi, b
    mov rdx, c
    syscall
}

;; ssize_t write(int fd, const void *buf, size_t count);
macro write fd, buf, count
{
    syscall3 SYS_write, fd, buf, count
}

;; int socket(int domain, int type, int protocol);
macro socket domain, type, protocol
{
    syscall3 SYS_socket, domain, type, protocol
}

;; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
macro bind sockfd, addr, addr_len
{
    syscall3 SYS_bind, sockfd, addr, addr_len
}

;;    int listen(int sockfd, int backlog);
macro listen sockfd, backlog
{
    syscall2 SYS_listen, sockfd, backlog
}

;; void _Exit(int status);
macro exit code
{
    syscall1 SYS_exit, code
}

;; int close(int fd);
macro close fd
{
    syscall1 SYS_close, fd
}

;; int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
macro accept sockfd, addr, addrlen
{
    syscall3 SYS_accept, sockfd, addr, addrlen
}

segment readable executable
entry main
main:
    write STDOUT, start, start_len
    write STDOUT, socket_trace_msg, socket_trace_msg_len

    ; Opening socket
    socket AF_INET, SOCK_STREAM, 0
    cmp rax, 0
    jl error
    mov qword [sockfd], rax

    ; Binding socket
    ; Implementing the same way as TCP server in C, just check here:
    ; https://www.geeksforgeeks.org/tcp-server-client-implementation-in-c/

    write STDOUT, bind_trace_msg, bind_trace_msg_len
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

    write STDOUT, listen_trace_msg, listen_trace_msg_len
    listen [sockfd], MAX_CONN
    cmp rax, 0
    jl error

    write STDOUT, accept_trace_msg, accept_trace_msg_len
    accept [sockfd], cliaddr.sin_family, cliaddr_len
    cmp rax, 0
    jl error

    mov qword [connfd], rax

    write STDOUT, ok_msg, ok_msg_len
    close [connfd]
    close [sockfd]
    exit EXIT_SUCCESS

error:
    write STDERR, error_msg, error_msg_len
    close [connfd]
    close [sockfd]
    exit EXIT_FAILURE

;; db - 1 byte -  8 bits
;; dw - 2 byte - 16 bits
;; dd - 4 byte - 32 bits
;; dq - 8 byte - 64 bits
segment readable writeable

struc servaddr_in
{
    .sin_family dw 0
    .sin_port   dw 0
    .sin_addr   dd 0
    .sin_zero   dq 0
}

sockfd dq -1
connfd dq -1
; struct sockaddr_in {
; 	sa_family_t sin_family;     // 16 bits
; 	in_port_t sin_port;         // 16 bits
; 	struct in_addr sin_addr;    // 32 bits
; 	uint8_t sin_zero[8];        // 64 bits
; };
servaddr servaddr_in
sizeof_servaddr = $ - servaddr.sin_family
cliaddr servaddr_in
cliaddr_len dd sizeof_servaddr

start db 'INFO: Starting Web Server', 10
start_len = $ - start
ok_msg db 'INFO: OK!', 10
ok_msg_len = $ - ok_msg
socket_trace_msg db 'INFO: Creating a socket...', 10
socket_trace_msg_len = $ - socket_trace_msg
bind_trace_msg db 'INFO: Binding the socket...', 10
bind_trace_msg_len = $ - bind_trace_msg
listen_trace_msg db 'INFO: Listening to the socket...', 10
listen_trace_msg_len = $ - listen_trace_msg
accept_trace_msg db 'INFO: Waiting for client connections...', 10
accept_trace_msg_len = $ - accept_trace_msg
error_msg db 'ERROR!', 10
error_msg_len = $ - error_msg
