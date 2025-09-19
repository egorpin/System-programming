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

    div [c]        ; al = b/c, ah = остаток

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

    xor rax, rax        ; обнуляем результат
    xor rcx, rcx        ; счётчик цифр
    xor rdx, rdx
    ;mov rsi, rdi        ; сохраняем указатель

    .loop:
        mov byte bl, [rsi + rdx]   ; получаем символ
        test rbx, rbx           ; конец строки?
        jz .exit

        sub rbx, '0'            ; преобразуем в цифру

        ; Умножаем текущий результат на 10 и добавляем цифру
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
    push rax            ; сохраняем исходное значение RAX
    push rbx            ; сохраняем RBX
    push rcx            ; сохраняем RCX
    push rdx            ; сохраняем RDX
    push rsi            ; сохраняем RSI
    push rdi            ; сохраняем RDI

    xor rbx, rbx        ; счётчик цифр

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

        ; Используем syscall
        push rbx        ; сохраняем счётчик
        mov rax, 1      ; sys_write
        mov rdi, 1      ; stdout
        mov rsi, place  ; буфер
        mov rdx, 1      ; длина
        syscall
        pop rbx         ; восстанавливаем счётчик

        dec rbx
        jnz .print_loop

    pop rdi             ; восстанавливаем RDI
    pop rsi             ; восстанавливаем RSI
    pop rdx             ; восстанавливаем RDX
    pop rcx             ; восстанавливаем RCX
    pop rbx             ; восстанавливаем RBX
    pop rax             ; восстанавливаем исходное значение RAX
    ret
