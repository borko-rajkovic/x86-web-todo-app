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

;; Check if text starts with the prefix (both strings are sized)
;;   rdi - void *text
;;   rsi - size_t text_len
;;   rdx - void *prefix
;;   r10 - size_t prefix_len
starts_with:
    xor rax, rax
    xor rbx, rbx
.next_char:
    cmp rsi, 0
    jle .done
    cmp r10,0
    jle .done

    mov al, byte [rdi]
    mov bl, byte [rdx]
    cmp rax, rbx
    jne .done

    dec rsi
    inc rdi
    dec r10
    inc rdx
    jmp .next_char

.done:
    cmp r10, 0
    je .yes
.no:
    mov rax, 0
    ret
.yes:
    mov rax, 1
    ret
