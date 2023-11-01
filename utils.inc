;; Generally useful utility functions

;; Write a NULL-terminated string to a file
;;   rdi - int fd
;;   rsi - const char *s
write_cstr:
    push rsi
    push rdi
    mov rdi, rsi
    call strlen

    mov rdx, rax
    mov rax, SYS_write
    pop rdi
    pop rsi
    syscall
    ret

;; Compute the length of a NULL-terminated string
;;   rdi - const char *s
strlen:
    push rdi
    xor rax, rax
.next_char:
    mov al, byte [rdi]
    cmp rax, 0
    je .done

    inc rdi
    jmp .next_char
.done:
    pop rsi
    sub rdi, rsi
    mov rax, rdi
    ret