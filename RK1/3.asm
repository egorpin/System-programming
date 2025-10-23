format ELF64
public _start

include '/home/egorp/cpp/System-programming/func.asm'

section '.data' writeable
filename_prefix      db "file_"
filename_prefix_len = $ - filename_prefix

section '.bss' writeable
directory     dq ?
n_str         dq ?
file_count    dq ?
filename_buffer    rb 32
random_bytes       rb 6

section '.text' executable
_start:
    pop rcx
    pop rsi
    pop rdi
    pop rsi
    mov [directory], rdi
    mov [n_str], rsi
    mov rax, 80
    mov rdi, [directory]
    syscall
    mov rsi, [n_str]
    call atoi
    mov [file_count], rax
    mov r12, 0
.create_loop:
    cmp r12, [file_count]
    jge .done
    call generate_random_name
    mov rax, 2
    mov rdi, filename_buffer
    mov rsi, 0100 or 01
    mov rdx, 0644o
    syscall
    mov rdi, rax
    mov rax, 3
    syscall
    inc r12
    jmp .create_loop
.done:
    mov rax, 60
    xor rdi, rdi
    syscall

generate_random_name:
    mov rsi, filename_prefix
    mov rdi, filename_buffer
    mov rcx, filename_prefix_len
    rep movsb
    mov rax, 318
    mov rdi, random_bytes
    mov rsi, 6
    xor rdx, rdx
    syscall
    mov rsi, random_bytes
    mov rdi, filename_buffer + filename_prefix_len
    mov rcx, 6
.convert_hex:
    mov al, [rsi]
    mov bl, al
    shr bl, 4
    call byte_to_hex
    mov [rdi], al
    inc rdi
    mov bl, al
    and bl, 0x0F
    call byte_to_hex
    mov [rdi], al
    inc rdi
    inc rsi
    loop .convert_hex
    mov byte [rdi], 0
    ret

byte_to_hex:
    cmp bl, 10
    jb .digit
    add bl, 'a' - 10
    mov al, bl
    ret
.digit:
    add bl, '0'
    mov al, bl
    ret
