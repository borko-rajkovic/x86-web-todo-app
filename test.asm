format ELF64 executable

SYS_write = 1
SYS_exit = 60

macro write fd, buf, count
{
    mov rax, SYS_write
    mov rdi, fd
    mov rsi, buf
    mov rdx, count
    syscall
}

macro exit code
{
    mov rax, SYS_exit
    mov rdi, code
    syscall
}

segment readable executable
entry main
main:
repeat 5
    write 1, msg, msg_len
end repeat
    exit 0

segment readable
msg db 'Hello, World!', 10
msg_len = $ - msg
