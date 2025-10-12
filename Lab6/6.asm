;;example6.asm
format ELF64

	public _start

	extrn initscr
	extrn start_color
	extrn init_pair
	extrn getmaxx
	extrn getmaxy
	extrn raw
	extrn noecho
	extrn keypad
	extrn stdscr
	extrn move
	extrn getch
	extrn clear
	extrn addch
	extrn refresh
	extrn endwin
	extrn exit
	extrn color_pair
	extrn insch
	extrn cbreak
	extrn timeout
	extrn mydelay
	extrn setrnd
	extrn get_random


	section '.bss' writable
	direction dq 0       ;; 0 = влево, 1 = вправо
	x dq 0              ;; Текущая координата X
	y dq 0              ;; Текущая координата Y
	max_x dq 0          ;; Максимальная координата X
	max_y dq 0          ;; Максимальная координата Y
	speed dq 10000             ;; Скорость заполнения
	palette dq 1        ;; Текущий цвет (1 = CYAN, 2 = MAGENTA)
	fill_complete dq 0  ;; 0 = заполняем CYAN, 1 = заполняем MAGENTA
	speed_level dq 1    ;; Уровень скорости (1-5)

	section '.data' writable
	fill_char db ' '    ;; Символ для заполнения
    digit db '          '

	section '.text' executable

_start:
	;; Инициализация
	call initscr

	;; Размеры экрана
	xor rdi, rdi
	mov rdi, [stdscr]
	call getmaxx
	mov [max_x], rax
	dec qword [max_x]    ;; Индексация с 0
	call getmaxy
	mov [max_y], rax
	dec qword [max_y]    ;; Индексация с 0

	call start_color

	;; Пара 1: CYAN фон
	mov rdx, 6          ;; COLOR_CYAN
	mov rsi, 6          ;; COLOR_CYAN
	mov rdi, 1          ;; Номер цветовой пары
	call init_pair

	;; Пара 2: MAGENTA фон
	mov rdx, 5          ;; COLOR_MAGENTA
	mov rsi, 5          ;; COLOR_MAGENTA
	mov rdi, 2          ;; Номер цветовой пары
	call init_pair

	call refresh
	call noecho
	call cbreak
	call setrnd

	;; Начинаем с ПРАВОГО верхнего угла
	mov rax, [max_x]
	mov [x], rax        ;; X = max_x (правый край)
	mov qword [y], 0    ;; Y = 0 (верхний край)
	mov qword [direction], 0  ;; Начинаем движение влево
	mov qword [palette], 0x100  ;; Начинаем с CYAN
	mov qword [fill_complete], 0  ;; Первое заполнение CYAN
	mov qword [speed_level], 1 ;; Начальный уровень скорости
	mov qword [speed], 10000          ;; Начальная скорость

mloop:
	;; Перемещаем курсор в текущую позицию
	mov rdi, [y]        ;; Y координата
	mov rsi, [x]        ;; X координата
	call move

	;; Выбираем цвет в зависимости от fill_complete
	mov rax, [fill_complete]
	cmp rax, 0
	je .cyan_fill
	jmp .magenta_fill

.cyan_fill:
	;; Заполняем CYAN
	call get_digit
	or rax, 0x100       ;; COLOR_PAIR(1) - CYAN
	mov [palette], rax
	jmp .print_char

.magenta_fill:
	;; Заполняем MAGENTA
	call get_digit
	or rax, 0x200       ;; COLOR_PAIR(2) - MAGENTA
	mov [palette], rax

.print_char:
	mov rdi, [palette]
	call addch

	;; Обновляем экран
	call refresh

	;; Двигаемся в текущем направлении
	mov rax, [direction]
	cmp rax, 0
	je .move_left
	jmp .move_right

.move_left:
	dec qword [x]       ;; Двигаемся влево
	cmp qword [x], 0
	jge .delay          ;; Если X >= 0, продолжаем

	;; Достигли левого края - переходим на следующую строку
	mov qword [x], 0    ;; Начинаем с левого края
	inc qword [y]       ;; Переходим на следующую строку
	mov qword [direction], 1  ;; Меняем направление на вправо
	jmp .check_bottom

.move_right:
	inc qword [x]       ;; Двигаемся вправо
	mov rax, [x]
	cmp rax, [max_x]
	jle .delay          ;; Если X <= max_x, продолжаем

	;; Достигли правого края - переходим на следующую строку
	mov rax, [max_x]
	mov [x], rax        ;; Начинаем с правого края
	inc qword [y]       ;; Переходим на следующую строку
	mov qword [direction], 0  ;; Меняем направление на влево

.check_bottom:
	;; Проверяем, достигли ли нижнего края
	mov rax, [y]
	cmp rax, [max_y]
	jle .delay          ;; Если Y <= max_y, продолжаем

	;; Достигли нижнего края
	mov rax, [fill_complete]
	cmp rax, 0
	jne .restart_cyan   ;; Если уже заполняли MAGENTA, начинаем заново с CYAN

	;; Переключаем на заполнение MAGENTA
	mov qword [fill_complete], 1
	jmp .restart_position

.restart_cyan:
	;; Начинаем заново с CYAN
	mov qword [fill_complete], 0

.restart_position:
	;; Сбрасываем позицию в правый верхний угол
	mov rax, [max_x]
	mov [x], rax        ;; X = max_x (правый край)
	mov qword [y], 0    ;; Y = 0 (верхний край)
	mov qword [direction], 0  ;; Начинаем движение влево

.delay:
	;; Задержка
	mov rdi, [speed]
	call mydelay

	;; Проверяем ввод пользователя
	mov rdi, 1
	call timeout
	call getch

	cmp rax, 'f'        ;; Изменить скорость
	je .change_speed
	cmp rax, 'x'        ;; Выход
	je next
	jmp mloop

.change_speed:
	;; Циклическое изменение скорости через 5 уровней
	mov rax, [speed_level]
	inc rax
	cmp rax, 6
	jl .set_speed_level
	mov rax, 1          ;; Циклируем обратно к уровню 1
.set_speed_level:
	mov [speed_level], rax

	;; Устанавливаем скорость в зависимости от уровня
	cmp rax, 1
	je .speed1
	cmp rax, 2
	je .speed2
	cmp rax, 3
	je .speed3
	cmp rax, 4
	je .speed4
	cmp rax, 5
	je .speed5

.speed1:
	mov qword [speed], 10000  ;; Очень медленно
	jmp mloop
.speed2:
	mov qword [speed], 5000  ;; Медленно
	jmp mloop
.speed3:
	mov qword [speed], 2000      ;; Средне
	jmp mloop
.speed4:
	mov qword [speed], 1000      ;; Быстро
	jmp mloop
.speed5:
	mov qword [speed], 500        ;; Очень быстро
	jmp mloop

next:
	call endwin
	mov rdi, 0
	call exit

;;Выбираем случайную цифру
get_digit:
	push rcx
	push rdx
	call get_random
	mov rcx, 10
	xor rdx, rdx
	div rcx
	xor rax,rax
	mov al, [digit + rdx]
	pop rdx
	pop rcx
	ret
