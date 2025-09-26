format ELF64
public _start
msg db 'Pingin', 10, 'Egor', 10, 'Vitalievich', 10, 0

_start:
    mov rax, 4
    mov rbx, 1
    mov rcx, msg
    mov rdx, 25
    int 0x80

    mov rax, 1
    xor rbx, rbx
    int 0x80
