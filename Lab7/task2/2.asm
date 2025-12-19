format ELF64

NUM_COUNT = 584
BUFFER_SIZE = NUM_COUNT * 4
SORTED_SIZE = NUM_COUNT * 4
DIGIT_COUNTS_SIZE = 10
TEMP_BUFFER_SIZE = 64

SYS_MMAP = 9
SYS_MUNMAP = 11
SYS_FORK = 57
SYS_WAIT4 = 61
SYS_EXIT = 60
SYS_NANOSLEEP = 35
SYS_WRITE = 1

MAP_PRIVATE = 0x02
MAP_ANONYMOUS = 0x20
PROT_READ = 1
PROT_WRITE = 2

section '.data' writable
    msg_fork_failed db "Ошибка создания процесса", 0xA, 0

    msg_process1 db "Процесс 1 - Количество чисел, сумма цифр которых кратна 3: ", 0
    msg_process2 db "Процесс 2 - Пятое после минимального: ", 0
    msg_process3 db "Процесс 3 - 0.75 квантиль: ", 0
    msg_process4 db "Процесс 4 - Наиболее редко встречающаяся цифра: ", 0
    msg_newline db 0xA, 0

    random_state dq 123456789

    timespec1:
        tv_sec1  dq 0
        tv_nsec1 dq 100000000

    timespec2:
        tv_sec2  dq 0
        tv_nsec2 dq 200000000

    timespec3:
        tv_sec3  dq 0
        tv_nsec3 dq 300000000

    timespec4:
        tv_sec4  dq 0
        tv_nsec4 dq 400000000

section '.bss' writable
    numbers_ptr dq ?      ; Указатель на массив чисел
    sorted_ptr dq ?       ; Указатель на отсортированный массив
    digit_counts_ptr dq ? ; Указатель на массив счетчиков цифр
    temp_buffer_ptr dq ?  ; Указатель на временный буфер

section '.text' executable
public _start

macro syscall1 number {
    mov rax, number
    syscall
}

macro syscall3 number, arg1, arg2, arg3 {
    mov rax, number
    mov rdi, arg1
    mov rsi, arg2
    mov rdx, arg3
    syscall
}

macro syscall6 number, arg1, arg2, arg3, arg4, arg5, arg6 {
    mov rax, number
    mov rdi, arg1
    mov rsi, arg2
    mov rdx, arg3
    mov r10, arg4
    mov r8, arg5
    mov r9, arg6
    syscall
}

allocate_memory:
    push rdi
    push rsi
    push rdx
    push r10
    push r8
    push r9

    xor rdi, rdi
    mov rsi, [rsp + 40]
    mov rdx, PROT_READ or PROT_WRITE
    mov r10, MAP_PRIVATE or MAP_ANONYMOUS
    mov r8, -1
    xor r9, r9

    mov rax, SYS_MMAP
    syscall

    pop r9
    pop r8
    pop r10
    pop rdx
    pop rsi
    pop rdi
    ret

free_memory:
    mov rax, SYS_MUNMAP
    syscall
    ret

print_string_sync:
    push rsi
    push rdx
    push rdi
    push rcx

    mov rsi, rdi
    xor rdx, rdx

.count_length:
    cmp byte [rsi + rdx], 0
    je .print
    inc rdx
    jmp .count_length

.print:
    mov rax, SYS_WRITE
    mov rdi, 1
    mov rsi, rsi
    mov rdx, rdx
    syscall

    pop rcx
    pop rdi
    pop rdx
    pop rsi
    ret

print_number_sync:
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi

    mov rax, rdi
    mov rbx, 10
    mov rsi, [temp_buffer_ptr]
    add rsi, TEMP_BUFFER_SIZE - 1
    mov byte [rsi], 0
    dec rsi

    test rax, rax
    jnz .convert_loop
    mov byte [rsi], '0'
    jmp .print_result

.convert_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    test rax, rax
    jnz .convert_loop

.print_result:
    inc rsi
    mov rdi, rsi
    call print_string_sync

    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret

sum_digits:
    push rbx
    push rcx
    push rdx

    mov rax, rdi
    xor rcx, rcx

.sum_loop:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    add rcx, rdx
    test rax, rax
    jnz .sum_loop

    mov rax, rcx

    pop rdx
    pop rcx
    pop rbx
    ret

random_limited:
    push rbx
    push rcx
    push rdx

    ; Генерируем случайное число
    mov rax, [random_state]
    mov rbx, rax
    shl rbx, 13
    xor rax, rbx
    mov rbx, rax
    shr rbx, 17
    xor rax, rbx
    mov rbx, rax
    shl rbx, 5
    xor rax, rbx
    mov [random_state], rax

    and rax, 0x7FFFFFFF

    xor rdx, rdx
    mov rbx, 1000
    div rbx

    mov rax, rdx

    pop rdx
    pop rcx
    pop rbx
    ret

nanosleep:
    mov rax, SYS_NANOSLEEP
    syscall
    ret

process1:
    mov rdi, timespec1
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process1]
    call print_string_sync

    mov rsi, [numbers_ptr]
    mov rcx, NUM_COUNT
    xor rbx, rbx

.process1_loop:
    mov edi, [rsi]
    call sum_digits

    xor rdx, rdx
    mov r8, 3
    div r8
    test rdx, rdx
    jnz .not_multiple

    inc rbx

.not_multiple:
    add rsi, 4
    dec rcx
    jnz .process1_loop

    mov rdi, rbx
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    ; Освобождаем память (в дочернем процессе)
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory

    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

process2:
    mov rdi, timespec2
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process2]
    call print_string_sync

    mov rsi, [numbers_ptr]
    mov rcx, NUM_COUNT

    mov ebx, [rsi]
    mov r8, rsi

.find_min_loop:
    mov eax, [rsi]
    cmp eax, ebx
    jge .not_min

    mov ebx, eax
    mov r8, rsi

.not_min:
    add rsi, 4
    dec rcx
    jnz .find_min_loop

    mov rsi, r8
    add rsi, 20

    mov rax, [numbers_ptr]
    add rax, BUFFER_SIZE
    cmp rsi, rax
    jl .valid_ptr

    mov rsi, rax
    sub rsi, 4

.valid_ptr:
    mov edi, [rsi]
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    ; Освобождаем память (в дочернем процессе)
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory

    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

process3:
    mov rdi, timespec3
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process3]
    call print_string_sync

    mov rsi, [numbers_ptr]
    mov rdi, [sorted_ptr]
    mov rcx, NUM_COUNT
.copy_loop:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec rcx
    jnz .copy_loop

    mov rcx, NUM_COUNT
    dec rcx
    jz .sort_done

.outer_loop:
    mov rbx, rcx
    mov rdi, [sorted_ptr]

.inner_loop:
    mov eax, [rdi]
    mov edx, [rdi + 4]
    cmp eax, edx
    jle .no_swap

    mov [rdi], edx
    mov [rdi + 4], eax

.no_swap:
    add rdi, 4
    dec rbx
    jnz .inner_loop

    loop .outer_loop

.sort_done:
    mov rax, NUM_COUNT
    mov rbx, 3
    mul rbx
    mov rbx, 4
    div rbx

    mov rsi, [sorted_ptr]
    shl rax, 2
    add rsi, rax
    mov edi, [rsi]
    call print_number_sync

    lea rdi, [msg_newline]
    call print_string_sync

    ; Освобождаем память (в дочернем процессе)
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory

    mov rdi, [sorted_ptr]
    mov rsi, SORTED_SIZE
    call free_memory

    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

process4:
    mov rdi, timespec4
    xor rsi, rsi
    call nanosleep

    lea rdi, [msg_process4]
    call print_string_sync

    ; Очищаем массив счетчиков цифр
    mov rdi, [digit_counts_ptr]
    mov rcx, 10
    xor al, al
.clear_loop:
    mov [rdi], al
    inc rdi
    dec rcx
    jnz .clear_loop

    mov rsi, [numbers_ptr]
    mov rcx, NUM_COUNT

.count_digits_loop:
    mov edi, [rsi]
    test edi, edi
    jz .next_number

.digit_loop:
    xor rdx, rdx
    mov rax, rdi
    mov rbx, 10
    div rbx

    mov rdi, rax
    mov r8, [digit_counts_ptr]
    inc byte [r8 + rdx]

    test rdi, rdi
    jnz .digit_loop

.next_number:
    add rsi, 4
    dec rcx
    jnz .count_digits_loop

    mov rsi, [digit_counts_ptr]
    mov al, 0xFF
    mov bl, -1
    mov rcx, 0

.find_min_digit:
    mov dl, [rsi + rcx]
    test dl, dl
    jz .skip_zero

    cmp dl, al
    jae .not_min_digit

    mov al, dl
    mov bl, cl

.not_min_digit:
.skip_zero:
    inc rcx
    cmp rcx, 10
    jl .find_min_digit

    cmp bl, -1
    jne .found_digit
    mov bl, 0

.found_digit:
    mov dil, bl
    add dil, '0'
    mov rsi, [temp_buffer_ptr]
    mov [rsi], dil
    mov byte [rsi + 1], 0

    mov rdi, rsi
    call print_string_sync

    lea rdi, [msg_newline]
    call print_string_sync

    ; Освобождаем память (в дочернем процессе)
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory

    mov rdi, [digit_counts_ptr]
    mov rsi, DIGIT_COUNTS_SIZE
    call free_memory

    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

_start:
    ; Выделяем память для массивов
    mov rdi, BUFFER_SIZE
    call allocate_memory
    cmp rax, -1
    je .mmap_error
    mov [numbers_ptr], rax

    mov rdi, SORTED_SIZE
    call allocate_memory
    cmp rax, -1
    je .mmap_error
    mov [sorted_ptr], rax

    mov rdi, DIGIT_COUNTS_SIZE
    call allocate_memory
    cmp rax, -1
    je .mmap_error
    mov [digit_counts_ptr], rax

    mov rdi, TEMP_BUFFER_SIZE
    call allocate_memory
    cmp rax, -1
    je .mmap_error
    mov [temp_buffer_ptr], rax

    ; Заполняем массив случайными числами от 0 до 999
    mov rsi, [numbers_ptr]
    mov rcx, NUM_COUNT

.fill_loop:
    call random_limited
    mov [rsi], eax
    add rsi, 4
    dec rcx
    jnz .fill_loop

    ; Создаем процессы
    mov r15, 4

.create_processes:
    syscall1 SYS_FORK

    test rax, rax
    jz .child_process
    js .fork_error

    push rax
    dec r15
    jnz .create_processes

.wait_loop:
    xor rdi, rdi
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    mov rax, SYS_WAIT4
    syscall

    test rax, rax
    jg .wait_loop

    ; Освобождаем память в родительском процессе
    ; (дочерние процессы уже освободили свою память)
    mov rdi, [numbers_ptr]
    mov rsi, BUFFER_SIZE
    call free_memory

    mov rdi, [sorted_ptr]
    mov rsi, SORTED_SIZE
    call free_memory

    mov rdi, [digit_counts_ptr]
    mov rsi, DIGIT_COUNTS_SIZE
    call free_memory

    mov rdi, [temp_buffer_ptr]
    mov rsi, TEMP_BUFFER_SIZE
    call free_memory

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.child_process:
    mov rax, 4
    sub rax, r15

    cmp rax, 1
    je process1
    cmp rax, 2
    je process2
    cmp rax, 3
    je process3
    jmp process4

.fork_error:
    lea rdi, [msg_fork_failed]
    call print_string_sync
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall

.mmap_error:
    ; Если mmap не удался, просто выходим
    mov rax, SYS_EXIT
    mov rdi, 1
    syscall
