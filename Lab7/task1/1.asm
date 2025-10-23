format ELF64

include '/home/egorp/cpp/System-programming/func.asm'

section '.data'
    prompt db '> ', 0

section '.bss'
    buffer rb 256
    child_pid dq 0
    status dq 0

section '.text'
public _start

_start:
    ; Выравниваем стек по 16 байтам
    and rsp, -16

main_loop:
    mov rsi, buffer
    call input_keyboard

    ; Замена символа новой строки на null
    dec rax
    mov byte [buffer + rax], 0

    ; Создание дочернего процесса
    mov rax, 57         ; sys_fork
    syscall

    cmp rax, 0
    jz child_process    ; если 0 -> дочерний процесс
    jg parent_process   ; если >0 -> родительский процесс

    ; Ошибка fork - продолжаем цикл
    jmp main_loop

parent_process:
    ; Сохраняем PID дочернего процесса
    mov [child_pid], rax

    ; Ожидание завершения дочернего процесса
    mov rax, 61         ; sys_wait4
    mov rdi, [child_pid]
    mov rsi, status
    mov rdx, 0
    mov r10, 0
    syscall

    jmp main_loop

child_process:
    ; Подготовка аргументов для execve
    mov rdi, buffer     ; filename

    ; Создаем argv массив с правильным выравниванием
    xor rax, rax
    push rax            ; NULL terminator
    push rdi            ; pointer to filename
    mov rsi, rsp        ; argv

    mov rdx, 0          ; envp = NULL

    ; Вызов execve
    mov rax, 59         ; sys_execve
    syscall

    ; Если execve завершился ошибкой
    mov rax, 60         ; sys_exit
    mov rdi, 1          ; код ошибки
    syscall

exit_program:
    ; Корректный выход из программы
    mov rax, 60         ; sys_exit
    xor rdi, rdi        ; код 0
    syscall
