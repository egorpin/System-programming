format ELF64
public _start
public exit

include '/home/egorp/cpp/System-programming/help.asm'

section '.bss' writable
    place db 1
    a dq 0
    b dq 0
    c dq 0

;(((b/c)*b)+b)
section '.text' executable
_start:
    add rsp, 16
    xor rsi, rsi
    xor rax, rax

    pop rsi
    call atoi
    mov [a], rax

    xor rsi, rsi
    pop rsi
    call atoi
    mov [b], rax

    xor rsi, rsi
    pop rsi
    call atoi
    mov [c], rax

    mov rax, [b]    ; al = b

    div [c]        ; al = b/c

    ; (b/c)*b
    mul [b]         ; ax = (b/c)*b

    ; ((b/c)*b)+b
    add rax, [b]

    call print
    call new_line

    call exit

atoi:
    push rbx
    push rcx
    push rdx
    push rsi

    xor rax, rax
    xor rcx, rcx
    xor rdx, rdx
    ;mov rsi, rdi

    .loop:
        mov byte bl, [rsi + rdx]
        test rbx, rbx
        jz .exit

        sub rbx, '0'


        imul rax, 10
        add rax, rbx

        inc rdi
        inc rdx
        jmp .loop

    .exit:
        pop rsi
        pop rdx
        pop rcx
        pop rbx
        ret

print:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    xor rbx, rbx

    mov rcx, 10
    .loop:
        xor rdx, rdx
        div rcx
        push rdx
        inc rbx
        test rax, rax
        jnz .loop

    .print_loop:
        pop rax
        add rax, '0'
        mov [place], al


        push rbx
        mov rax, 1
        mov rdi, 1
        mov rsi, place
        mov rdx, 1
        syscall
        pop rbx

        dec rbx
        jnz .print_loop

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
