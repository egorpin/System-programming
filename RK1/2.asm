format ELF64
public _start

include '/home/egorp/cpp/System-programming/help.asm'

section '.data' writable
    newline db 0xA

section '.bss' writable
    result rq 1

section '.text' executable
_start:
    pop rcx
    pop rsi
    pop rsi

    xor r8, r8
    xor rcx, rcx

convert_loop:
    mov al, [rsi + rcx]
    cmp al, 0
    je convert_done

    sub al, '0'
    imul r8, 10
    add r8, rax

    inc rcx
    jmp convert_loop

convert_done:
    xor rax, rax
    mov rbx, 1

sum_loop:
    mov r9, rbx

    mov r10, rbx
find_first_digit:
    cmp r10, 10
    jl first_digit_found

    xor rdx, rdx
    mov rax, r10
    mov rcx, 10
    div rcx
    mov r10, rax
    jmp find_first_digit

first_digit_found:
    xor rax, rax
    mov rax, r9
    mul r10
    add [result], rax

    inc rbx
    cmp rbx, r8
    jle sum_loop

    mov rax, [result]
    call print_int

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    call exit
