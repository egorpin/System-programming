format ELF64
public _start
public exit

section '.data' writeable
    input_buf       rb 256
    arg_array       rq 12

    prog_run5       db './asm5', 0
    arg1_run5       db 'input.txt', 0
    arg2_run5       db 'output.txt', 0

    prog_run6       db './asm6', 0

    cmd_run5        db 'Run5', 0
    cmd_run6        db 'Run6', 0
    cmd_exit        db 'exit', 0

    child_id        dq 0
    status          dq 0

    environ         dq 0

    cursor          db '$ ', 0
    err_cmd         db 'Command not found', 10, 0
    err_fork        db 'Process creation failed', 10, 0
    newline         db 10, 0

section '.text' executable

; Функция для вывода новой строки
print_newline:
    push rax
    push rdi
    push rsi
    push rdx

    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret

_start:
    mov r12, rsp
    add r12, 8

    .env_scan:
        cmp qword [r12], 0
        je .env_found
        add r12, 8
        jmp .env_scan

    .env_found:
        add r12, 8
        mov [environ], r12

    .shell_loop:
        ; Вывод приглашения
        mov rax, 1
        mov rdi, 1
        mov rsi, cursor
        mov rdx, 2
        syscall

        ; Чтение ввода пользователя
        mov rax, 0
        mov rdi, 0
        mov rsi, input_buf
        mov rdx, 255
        syscall

        ; Проверка на EOF или ошибку
        cmp rax, 0
        jle exit

        ; Убираем символ новой строки из ввода
        mov rcx, rax
        dec rcx
        cmp byte [input_buf + rcx], 10
        jne .process_input
        mov byte [input_buf + rcx], 0

    .process_input:
        mov rsi, input_buf
        mov rdi, arg_array
        xor rcx, rcx  ; Счетчик токенов

    .get_tokens:
        cmp byte [rsi], ' '
        je .next_char
        cmp byte [rsi], 9        ; табуляция
        je .next_char
        cmp byte [rsi], 0
        je .all_tokens

        ; Сохраняем указатель на токен
        mov [rdi + rcx*8], rsi
        inc rcx

    .find_end:
        inc rsi
        cmp byte [rsi], ' '
        je .word_end
        cmp byte [rsi], 9
        je .word_end
        cmp byte [rsi], 0
        je .all_tokens
        jmp .find_end

    .word_end:
        mov byte [rsi], 0
        inc rsi
        jmp .get_tokens

    .next_char:
        inc rsi
        jmp .get_tokens

    .all_tokens:
        ; Завершаем массив аргументов нулем
        mov qword [rdi + rcx*8], 0

        ; Проверяем, есть ли токены
        cmp rcx, 0
        je .shell_loop

        ; Получаем первый токен (команду)
        mov rsi, [arg_array]

        ; Проверка команды exit
        mov rdi, cmd_exit
        call compare_strings
        test rax, rax
        jz exit

        ; Проверка команды Run5
        mov rsi, [arg_array]
        mov rdi, cmd_run5
        call compare_strings
        test rax, rax
        jz .exec_run5

        ; Проверка команды Run6
        mov rsi, [arg_array]
        mov rdi, cmd_run6
        call compare_strings
        test rax, rax
        jz .exec_run6

        ; Неизвестная команда
        mov rax, 1
        mov rdi, 1
        mov rsi, err_cmd
        mov rdx, 18
        syscall
        jmp .shell_loop

    .exec_run5:
        ; Для Run5 используем предопределенные аргументы
        mov qword [arg_array], prog_run5
        mov qword [arg_array + 8], arg1_run5
        mov qword [arg_array + 16], arg2_run5
        mov qword [arg_array + 24], 0

        mov r13, prog_run5
        jmp .create_process

    .exec_run6:
        ; Для Run6 используем введенные аргументы
        ; Но первый аргумент должен быть "./asm6", а не "Run6"
        mov qword [arg_array], prog_run6

        mov r13, prog_run6
        jmp .create_process

    .create_process:
        ; Системный вызов fork
        mov rax, 57
        syscall

        cmp rax, 0
        jl .fork_fail
        je .run_program

        ; Родительский процесс
        mov [child_id], rax
        jmp .wait_process

    .run_program:
        ; Системный вызов execve
        mov rax, 59
        mov rdi, r13          ; filename
        mov rsi, arg_array    ; argv
        mov rdx, [environ]    ; envp
        syscall

        ; Если execve не удался
        call error_exit

    .wait_process:
        ; Системный вызов wait4
        mov rax, 61
        mov rdi, [child_id]
        mov rsi, status
        xor rdx, rdx
        xor r10, r10
        syscall

        ; Добавляем новую строку после завершения дочернего процесса
        call print_newline

        jmp .shell_loop

    .fork_fail:
        mov rax, 1
        mov rdi, 1
        mov rsi, err_fork
        mov rdx, 25
        syscall
        jmp .shell_loop

error_exit:
    mov rax, 60
    mov rdi, 1
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

compare_strings:
    push rsi
    push rdi
    push rbx

    .compare_loop:
        mov al, [rsi]
        mov bl, [rdi]
        cmp al, bl
        jne .different
        test al, al
        jz .identical
        inc rsi
        inc rdi
        jmp .compare_loop

    .different:
        mov rax, 1
        jmp .finish

    .identical:
        xor rax, rax

    .finish:
        pop rbx
        pop rdi
        pop rsi
        ret
