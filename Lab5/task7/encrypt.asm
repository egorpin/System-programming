format ELF64
public _start

include '/home/egorp/cpp/System-programming/func.asm'

section '.bss' writable
    input_fd     dq 0
    output_fd    dq 0
    bytes_read   dq 0
    shift_value  dq 0

section '.data' writable
    BUFFER_SIZE equ 65536
    buffer       rb BUFFER_SIZE
    newline db 0x0A

section '.text' executable
_start:
    mov r8, [rsp + 16]
    mov r9, [rsp + 24]

    mov rsi, [rsp + 32]
    call atoi
    mov [shift_value], rax

    mov rax, 2
    mov rdi, r8
    mov rsi, 0
    mov rdx, 0
    syscall
    mov [input_fd], rax

    mov rax, 0
    mov rdi, [input_fd]
    mov rsi, buffer
    mov rdx, BUFFER_SIZE
    syscall
    cmp rax, 0
    jle .close_input
    mov [bytes_read], rax

.close_input:
    mov rax, 3
    mov rdi, [input_fd]
    syscall

    mov rsi, buffer
    mov rcx, [bytes_read]
    mov rdx, [shift_value]
    call .encrypt

.write_output:
    mov rax, 2
    mov rdi, r9
    mov rsi, 101o
    mov rdx, 644o
    syscall
    mov [output_fd], rax

    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, buffer
    mov rdx, [bytes_read]
    syscall

    mov rax, 3
    mov rdi, [output_fd]
    syscall

    jmp exit

.encrypt:
    test rcx, rcx
    jz .encrypt_done

    mov rbx, [shift_value]   ; загружаем сдвиг в rbx
    mov bl, 3
    mov r8b, 26

.encrypt_loop:
    mov al, [rsi]

    ; (A-Z)
    cmp al, 'A'
    jb .next_char
    cmp al, 'Z'
    ja .check_lowercase

    sub al, 'A'
    add al, bl
    cmp al, r8b
    jl .process_shift_upper
    sub al, 26

.process_shift_upper:
    add al, 'A'
    jmp .store_char

.check_lowercase:
    ; (a-z)
    cmp al, 'a'
    jb .next_char
    cmp al, 'z'
    ja .next_char

    sub al, 'a'
    add al, bl
    cmp al, r8b
    jl .process_shift_lower
    sub al, 26

.process_shift_lower:
    add al, 'a'

.store_char:
    mov [rsi], al

.next_char:
    inc rsi
    dec rcx
    jnz .encrypt_loop

.encrypt_done:
    ret

exit:
    mov rax, 60
    xor rdi, rdi
    syscall
