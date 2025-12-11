format ELF64
public _start

sys_write     = 1
sys_clone     = 56
sys_wait4     = 61
sys_exit      = 60
sys_brk       = 12
sys_getrandom = 318
sys_mmap      = 9

CLONE_VM      = 0x00000100
CLONE_FILES   = 0x00000400
CLONE_SIGHAND = 0x00000800
SIGCHLD       = 17
CLONE_FLAGS   = 0xD11

PROT_READ     = 0x1
PROT_WRITE    = 0x2
MAP_PRIVATE   = 0x2
MAP_ANONYMOUS = 0x20
MAP_GROWSDOWN = 0x1000
PROT_RW       = 3
MAP_FLAGS     = 0x1022

STACK_SIZE    = 0x100000

section '.data'

msg_error_arg      db "Error: Please provide array size as parameter", 10, 0
msg_error_clone    db "Error: Clone failed", 10, 0
msg_mmap_fail      db "Error: Stack allocation failed (mmap)", 10, 0
msg_array          db "Array: ", 0
msg_even_sum       db "Sum of even indices: ", 0
msg_odd_sum        db "Sum of odd indices: ", 0
bracket_open       db "[", 0
bracket_close      db "]", 0
colon              db ":", 0
space              db " ", 0
newline            db 10, 0

array_size         dq 0
array_ptr          dq 0
sum_even           dq 0
sum_odd            dq 0
pid1               dq 0
pid2               dq 0
stack_ptr1         dq 0
stack_ptr2         dq 0


section '.text'

allocate_stack_mmap:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    mov rbx, rdi

    mov rax, sys_mmap
    xor rdi, rdi
    mov rsi, rbx

    mov rdx, PROT_RW
    mov r10, MAP_FLAGS

    mov r8, -1
    xor r9, r9
    syscall

    cmp rax, -4096
    jg .mmap_ok

    mov rax, 0
    jmp .restore_stack

.mmap_ok:

.restore_stack:
    add rsp, 8
    pop rbp
    ret

print_string:
    push rdi
    call strlen
    pop rdi

    mov rdx, rax
    mov rax, sys_write
    mov rsi, rdi
    mov rdi, 1
    syscall
    ret

strlen:
    xor rax, rax
.length_loop:
    cmp byte [rdi + rax], 0
    je .length_done
    inc rax
    jmp .length_loop
.length_done:
    ret

print_int:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rax, rdi
    mov rbx, 10
    lea rsi, [rbp - 1]
    mov byte [rsi], 0

    test rax, rax
    jnz .convert_loop_int

    dec rsi
    mov byte [rsi], '0'
    mov rdi, rsi
    call print_string
    jmp .restore_stack

.convert_loop_int:
    dec rsi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rsi], dl
    test rax, rax
    jnz .convert_loop_int

    mov rdi, rsi
    call print_string

.restore_stack:
    mov rsp, rbp
    pop rbp
    ret

print_array:
    push rbx
    push r12
    push r13

    mov rbx, rdi
    mov r12, rsi
    xor r13, r13

    push rdi
    mov rdi, msg_array
    call print_string
    pop rdi

.print_array_loop:
    cmp r13, r12
    jge .print_array_done

    push r12
    mov rdi, bracket_open
    call print_string
    pop r12

    push r12
    mov rdi, r13
    call print_int
    pop r12

    push r12
    mov rdi, colon
    call print_string
    pop r12

    push r12
    mov rdi, [rbx + r13 * 8]
    call print_int
    pop r12

    push r12
    mov rdi, bracket_close
    call print_string
    pop r12

    cmp r13, r12
    je .no_space

    push r12
    mov rdi, space
    call print_string
    pop r12
.no_space:

    inc r13
    jmp .print_array_loop

.print_array_done:
    push r12
    mov rdi, newline
    call print_string
    pop r12

    pop r13
    pop r12
    pop rbx
    ret

string_to_int:
    xor rax, rax
    mov rbx, 10
.loop:
    movzx rcx, byte [rdi]
    cmp cl, '0'
    jl .done
    cmp cl, '9'
    jg .done
    sub cl, '0'
    imul rax, rbx
    add rax, rcx
    inc rdi
    jmp .loop
.done:
    ret


allocate_memory:
    push rbx

    mov rbx, rdi

    mov rax, sys_brk
    xor rdi, rdi
    syscall

    mov rdi, rax
    mov rsi, rax
    add rsi, rbx

    mov rax, sys_brk
    syscall

    cmp rax, rsi
    jne .error_alloc

    mov rax, rdi
    pop rbx
    ret

.error_alloc:
    xor rax, rax
    pop rbx
    ret

fill_array_random:
    push rbx
    push r12
    push r13
    push r14

    mov rbx, rdi
    mov r12, rsi
    xor r13, r13

    mov r14, 0

    mov rax, sys_brk
    xor rdi, rdi
    syscall
    mov r14, rax

    mov rdi, rax
    add rdi, 8
    mov rax, sys_brk
    syscall

.fill_loop:
    cmp r13, r12
    jge .fill_done

    mov rax, sys_getrandom
    mov rdi, r14
    mov rsi, 8
    mov rdx, 0
    syscall

    mov r8, [r14]
    mov [rbx + r13 * 8], r8

    inc r13
    jmp .fill_loop

.fill_done:
    mov rax, sys_brk
    mov rdi, r14
    syscall

    pop r14
    pop r13
    pop r12
    pop rbx
    ret

child_func_even:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov rbx, rdi
    mov r12, rsi
    xor r13, r13
    xor r14, r14

.even_loop:
    cmp r13, r12
    jge .even_done

    test r13, 1
    jnz .skip_even

    mov r8, [rbx + r13 * 8]
    add r14, r8

.skip_even:
    add r13, 1
    jmp .even_loop

.even_done:
    mov r8, [sum_even]
    add r8, r14
    mov [sum_even], r8

    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp

    mov rax, sys_exit
    xor rdi, rdi
    syscall
    ret

child_func_odd:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14

    mov rbx, rdi
    mov r12, rsi
    xor r13, r13
    xor r14, r14

.odd_loop:
    cmp r13, r12
    jge .odd_done

    test r13, 1
    jz .skip_odd

    mov r8, [rbx + r13 * 8]
    add r14, r8

.skip_odd:
    add r13, 1
    jmp .odd_loop

.odd_done:
    mov r8, [sum_odd]
    add r8, r14
    mov [sum_odd], r8

    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp

    mov rax, sys_exit
    xor rdi, rdi
    syscall
    ret


_start:
    cmp rdi, 2
    jne .error_arg

    mov rdi, rsi
    add rdi, 8
    mov rdi, [rdi]
    call string_to_int
    mov [array_size], rax

    mov rdi, [array_size]
    imul rdi, 8
    call allocate_memory
    mov [array_ptr], rax

    mov rdi, [array_ptr]
    mov rsi, [array_size]
    call fill_array_random

    mov rdi, [array_ptr]
    mov rsi, [array_size]
    call print_array

    mov rdi, STACK_SIZE
    call allocate_stack_mmap
    test rax, rax
    jz .error_mmap
    mov [stack_ptr1], rax
    mov r15, rax

    mov rdi, STACK_SIZE
    call allocate_stack_mmap
    test rax, rax
    jz .error_mmap
    mov [stack_ptr2], rax
    mov r14, rax

    mov rdi, CLONE_FLAGS
    mov rsi, r15
    add rsi, STACK_SIZE - 16
    mov rdx, child_func_even
    mov rcx, [array_ptr]
    mov r8, [array_size]
    mov r9, 0

    mov rax, sys_clone
    syscall

    cmp rax, 0
    jl .error_clone
    mov [pid1], rax

    mov rdi, CLONE_FLAGS
    mov rsi, r14
    add rsi, STACK_SIZE - 16
    mov rdx, child_func_odd
    mov rcx, [array_ptr]
    mov r8, [array_size]
    mov r9, 0

    mov rax, sys_clone
    syscall

    cmp rax, 0
    jl .error_clone
    mov [pid2], rax

    mov rax, sys_wait4
    mov rdi, [pid1]
    xor rsi, rsi
    xor rdx, rdx
    xor rcx, rcx
    syscall

    mov rax, sys_wait4
    mov rdi, [pid2]
    xor rsi, rsi
    xor rdx, rdx
    xor rcx, rcx
    syscall

    mov rdi, msg_even_sum
    call print_string
    mov rdi, [sum_even]
    call print_int

    mov rdi, msg_odd_sum
    call print_string
    mov rdi, [sum_odd]
    call print_int

    mov rdi, newline
    call print_string

    jmp .exit


.error_arg:
    mov rdi, msg_error_arg
    call print_string
    mov rdi, 1
    jmp .exit

.error_clone:
    mov rdi, msg_error_clone
    call print_string
    mov rdi, 1
    jmp .exit

.error_mmap:
    mov rdi, msg_mmap_fail
    call print_string
    mov rdi, 1
    jmp .exit

.exit:
    mov rax, sys_exit
    syscall
