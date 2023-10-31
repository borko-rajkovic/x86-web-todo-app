format ELF64 executable

SYS_write equ 1
SYS_close equ 3
SYS_exit equ 60
SYS_socket equ 41
SYS_bind equ 49

AF_INET equ 2
INADDR_ANY equ 0
SOCK_STREAM equ 1

STDOUT equ 1
STDERR equ 2

EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

macro write fd, buf, count
{
    mov rax, SYS_write
    mov rdi, fd
    mov rsi, buf
    mov rdx, count
    syscall
}

;; int socket(int domain, int type, int protocol);
macro socket domain, type, protocol
{
    mov rax, SYS_socket
    mov rdi, domain
    mov rsi, type
    mov rdx, protocol
    syscall
}

macro syscall3 number, a, b, c {
    mov rax, number
    mov rdi, a
    mov rsi, b
    mov rdx, c
    syscall
}

; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);

macro bind sockfd, addr, addr_len
{
    syscall3 SYS_bind, sockfd, addr, addr_len
}

macro exit code
{
    mov rax, SYS_exit
    mov rdi, code
    syscall
}

macro close fd {
    mov rax, SYS_close
    mov rdi, fd
    syscall
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

    write STDOUT, ok_msg, ok_msg_len
    close [sockfd]
    exit EXIT_SUCCESS

error:
    write STDERR, error_msg, error_msg_len
    close [sockfd]
    exit EXIT_FAILURE

;; db - 1 byte -  8 bits
;; dw - 2 byte - 16 bits
;; dd - 4 byte - 32 bits
;; dq - 8 byte - 64 bits

segment readable writeable

sockfd dq 0
; struct sockaddr_in {
; 	sa_family_t sin_family;     // 16 bits
; 	in_port_t sin_port;         // 16 bits
; 	struct in_addr sin_addr;    // 32 bits
; 	uint8_t sin_zero[8];        // 64 bits
; };
servaddr.sin_family dw 0
servaddr.sin_port   dw 0
servaddr.sin_addr   dd 0
servaddr.sin_zero   dq 0
sizeof_servaddr = $ - servaddr.sin_family

start db 'INFO: Starting Web Server', 10
start_len = $ - start
ok_msg db 'INFO: OK!', 10
ok_msg_len = $ - ok_msg
socket_trace_msg db 'INFO: Creating a socket...', 10
socket_trace_msg_len = $ - socket_trace_msg
bind_trace_msg db 'INFO: Binding the socket...', 10
bind_trace_msg_len = $ - bind_trace_msg
error_msg db 'ERROR!', 10
error_msg_len = $ - error_msg
