format elf64

public _start

extrn printf

section '.data' writable
    header        db "%-15s%-20s", 0xA, 0
    table_row     db "%-15.6f%-20d", 0xA, 0

    header_eps    db "погрешность", 0
    header_factors db "  множители", 0

    result_msg    db "Целевое значение sqrt(2)/2 = %.10f", 0xA, 0
    newline       db 0xA, 0

    const_1       dq 1.0
    const_2       dq 2.0
    const_m1      dq -1.0
    target_value  dq 0.7071067811865475  ; √2/2

    epsilons      dq 0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001
    eps_count     dq 6

section '.bss' writable
    epsilon       rq 1      ; Текущая погрешность
    product       rq 1      ; Текущее произведение
    diff          rq 1      ; Разность с целевым значением
    factor_count  rq 1      ; Количество сомножителей
    k             rq 1      ; Индекс сомножителя
    sign          rq 1      ; Знак (-1)^k
    denominator   rq 1      ; Знаменатель (2k+1)
    factor        rq 1      ; Текущий множитель

section '.text' executable

compute_product:
    push rbp
    mov rbp, rsp

    ; Инициализация
    finit
    fld1
    fstp qword [product]    ; product = 1.0

    mov qword [factor_count], 0
    mov qword [k], 1
    mov qword [sign], -1

.product_loop:
    inc qword [factor_count]

    finit

    ; Вычисляем 2k+1
    fild qword [k]
    fld qword [const_2]
    fmulp st1, st0
    fld1
    faddp st1, st0
    fst qword [denominator]

    ; Вычисляем (-1)^k / (2k+1)
    fild qword [sign]
    fdiv qword [denominator]

    fld1
    faddp st1, st0

    fmul qword [product]
    fst qword [product]

    ; --- Проверка точности ---
    fld qword [target_value]
    fsubp st1, st0
    fabs
    fstp qword [diff]

    finit
    fld qword [diff]
    fld qword [epsilon]

    fcomip st1
    fstp st0

    ja .converged

    inc qword [k]

    mov rax, [sign]
    neg rax
    mov [sign], rax

    cmp qword [factor_count], 100000000
    jl .product_loop

    jmp .done

.converged:
.done:
    leave
    ret

_start:
    and rsp, -16

    ; Печать заголовка
    mov rdi, header
    mov rsi, header_eps
    mov rdx, header_factors
    xor rax, rax
    call printf

    mov rbx, 0

.table_loop:
    cmp rbx, [eps_count]
    jge .print_result

    mov rax, [epsilons + rbx*8]
    mov [epsilon], rax

    call compute_product

    mov rdi, table_row
    movq xmm0, [epsilon]
    mov rsi, [factor_count]
    mov rax, 1
    call printf

    inc rbx
    jmp .table_loop

.print_result:
    mov rdi, newline
    call printf

    mov rdi, result_msg
    movq xmm0, [target_value]
    mov rax, 1
    call printf

    mov rax, 60
    xor rdi, rdi
    syscall
