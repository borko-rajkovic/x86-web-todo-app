;; Linux related constants and macros

SYS_read equ 0
SYS_open equ 2
SYS_write equ 1
SYS_exit equ 60
SYS_socket equ 41
SYS_accept equ 43
SYS_bind equ 49
SYS_listen equ 50
SYS_close equ 3
SYS_setsockopt equ 54
SYS_fstat64 equ 5

O_RDONLY = 0
O_WRONLY = 1
O_CREAT = 64
O_TRUNC = 512

AF_INET equ 2
SOCK_STREAM equ 1
INADDR_ANY equ 0

SOL_SOCKET = 1
SO_REUSEADDR = 2
SO_REUSEPORT = 15

STDOUT equ 1
STDERR equ 2

EXIT_SUCCESS equ 0
EXIT_FAILURE equ 1

; struct stat64 {
; 	unsigned long long	st_dev;
; 	unsigned char	__pad0[4];

; 	unsigned long	__st_ino;

; 	unsigned int	st_mode;
; 	unsigned int	st_nlink;

; 	unsigned long	st_uid;
; 	unsigned long	st_gid;

; 	unsigned long long	st_rdev;
; 	unsigned char	__pad3[4];

; 	long long	st_size;
; 	unsigned long	st_blksize;

; 	/* Number 512-byte blocks allocated. */
; 	unsigned long long	st_blocks;

; 	unsigned long	st_atime;
; 	unsigned long	st_atime_nsec;

; 	unsigned long	st_mtime;
; 	unsigned int	st_mtime_nsec;

; 	unsigned long	st_ctime;
; 	unsigned long	st_ctime_nsec;

; 	unsigned long long	st_ino;
; };

sizeof_stat64 = 144
stat64.st_size = 48 ; offset to start of st_size in stat64

macro funcall2 func, a, b
{
    mov rdi, a
    mov rsi, b
    call func
}

macro funcall3 func, a, b, c
{
    mov rdi, a
    mov rsi, b
    mov rdx, c
    call func
}

macro funcall4 func, a, b, c, d
{
    mov rdi, a
    mov rsi, b
    mov rdx, c
    mov r10, d
    call func
}

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

macro syscall5 number, a, b, c, d, e
{
    mov rax, number
    mov rdi, a
    mov rsi, b
    mov rdx, c
    mov r10, d
    mov r8,  e
    syscall
}

;; ssize_t write(int fd, const void *buf, size_t count);
macro write fd, buf, count
{
    syscall3 SYS_write, fd, buf, count
}

;; ssize_t read(int fd, void *buf, size_t count);
macro read fd, buf, count
{
    syscall3 SYS_read, fd, buf, count
}

;; int close(int fd);
macro close fd
{
    syscall1 SYS_close, fd
}

;; int socket(int domain, int type, int protocol);
macro socket domain, type, protocol
{
    syscall3 SYS_socket, domain, type, protocol
}

;; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
macro bind sockfd, addr, addrlen
{
    syscall3 SYS_bind, sockfd, addr, addrlen
}

;;       int listen(int sockfd, int backlog);
macro listen sockfd, backlog
{
    syscall2 SYS_listen, sockfd, backlog
}

;; int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
macro accept sockfd, addr, addrlen
{
    syscall3 SYS_accept, sockfd, addr, addrlen
}

;; void _Exit(int status);
macro exit code
{
    syscall1 SYS_exit, code
}

;; int open(const char *pathname, int flags, mode_t mode);
macro open filename, flags, mode
{
    syscall3 SYS_open, filename, flags, mode
}

;; db - 1 byte -  8 bits
;; dw - 2 byte - 16 bits
;; dd - 4 byte - 32 bits
;; dq - 8 byte - 64 bits

; struct sockaddr_in {
; 	sa_family_t sin_family;     // 16 bits
; 	in_port_t sin_port;         // 16 bits
; 	struct in_addr sin_addr;    // 32 bits
; 	uint8_t sin_zero[8];        // 64 bits
; };
struc servaddr_in
{
    .sin_family dw 0
    .sin_port   dw 0
    .sin_addr   dd 0
    .sin_zero   dq 0
}

;; int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
macro setsockopt sockfd, level, optname, optval, optlen
{
    syscall5 SYS_setsockopt, sockfd, level, optname, optval, optlen
}

;; int fstat(int fd, struct stat *statbuf);
macro fstat64 fd, statbuf
{
    syscall2 SYS_fstat64, fd, statbuf
} 
