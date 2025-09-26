format ELF64
public _start

section '.bss' writable
    input_fd dq ?
    output_fd dq ?
    file_size dq ?
    buffer_size = 65536
    file_buffer rb buffer_size
    line_ptrs rq 1000
    line_count dq ?
    input_filename dq ?
    output_filename dq ?

section '.data' writable
    newline db 10

section '.text' executable

_start:
    ; Получаем аргументы командной строки
    pop rcx
    cmp rcx, 3
    jne exit

    pop rsi
    pop rdi
    mov [input_filename], rdi
    pop rsi
    mov [output_filename], rsi

    ; Открываем входной файл
    mov rax, 2
    mov rdi, [input_filename]
    mov rsi, 0
    syscall
    mov [input_fd], rax

    ; Читаем файл
    mov rax, 0
    mov rdi, [input_fd]
    mov rsi, file_buffer
    mov rdx, buffer_size
    syscall
    mov [file_size], rax

    ; Закрываем входной файл
    mov rax, 3
    mov rdi, [input_fd]
    syscall

    ; Парсим строки
    call parse_lines

    ; Создаем выходной файл
    mov rax, 2
    mov rdi, [output_filename]
    mov rsi, 577
    mov rdx, 438
    syscall
    mov [output_fd], rax

    ; Записываем строки в обратном порядке
    call write_lines

    ; Закрываем выходной файл
    mov rax, 3
    mov rdi, [output_fd]
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

parse_lines:
    mov rsi, file_buffer      ; текущая позиция в буфере
    mov rdi, line_ptrs        ; массив указателей на строки
    mov qword [line_count], 0
    mov [rdi], rsi            ; первая строка начинается здесь
    inc qword [line_count]

    mov r8, file_buffer       ; начало буфера
    add r8, [file_size]       ; конец буфера

.parse_loop:
    cmp rsi, r8               ; дошли до конца буфера?
    jge .parse_done

    mov al, [rsi]
    cmp al, 10                ; символ новой строки?
    jne .next_char

    ; Нашли конец строки
    mov byte [rsi], 0         ; заменяем \n на 0
    inc rsi                   ; переходим к следующему символу

    ; Сохраняем указатель на начало следующей строки
    mov [rdi + 8], rsi
    add rdi, 8
    inc qword [line_count]

    ; Проверяем не превысили ли лимит строк
    mov rax, [line_count]
    cmp rax, 1000
    jge .parse_done

    jmp .parse_loop

.next_char:
    inc rsi
    jmp .parse_loop

.parse_done:
    ret

write_lines:
    mov rcx, [line_count]
    dec rcx
    js .write_done            ; если нет строк - выходим

.write_loop:
    ; Получаем указатель на строку
    mov rax, rcx
    shl rax, 3
    mov rsi, [line_ptrs + rax]

    ; Вычисляем длину строкы
    mov rdi, rsi
    xor rdx, rdx
.find_length:
    cmp byte [rdi], 0
    je .write_string
    inc rdi
    inc rdx
    jmp .find_length

.write_string:
    ; Записываем строку
    mov rax, 1
    mov rdi, [output_fd]
    syscall

    ; Записываем перевод строки
    mov rax, 1
    mov rdi, [output_fd]
    mov rsi, newline
    mov rdx, 1
    syscall

    dec rcx
    jns .write_loop

.write_done:
    ret
