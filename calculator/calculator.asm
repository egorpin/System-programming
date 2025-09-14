format ELF executable
entry _start

segment readable writeable
    prompt db 'Please enter your name: ', 0
    prompt_len = $ - prompt

    greeting db 'Hello, ', 0
    greeting_len = $ - greeting

    newline db 10, 0
    newline_len = $ - newline

    buffer db 256 dup(0)
    buffer_len = 256

segment readable executable
_start:
    ; Display prompt message
    mov eax, 4              ; sys_write
    mov ebx, 1              ; stdout
    mov ecx, prompt         ; message
    mov edx, prompt_len     ; length
    int 0x80

    ; Read user input
    mov eax, 3              ; sys_read
    mov ebx, 0              ; stdin
    mov ecx, buffer         ; buffer
    mov edx, buffer_len     ; max length
    int 0x80
    mov esi, eax            ; save bytes read

    ; Display greeting
    mov eax, 4              ; sys_write
    mov ebx, 1              ; stdout
    mov ecx, greeting       ; message
    mov edx, greeting_len   ; length
    int 0x80

    ; Remove newline from input if present
    cmp byte [buffer + esi - 1], 10
    jne .no_newline
    dec esi                 ; exclude newline
.no_newline:

    ; Display user's name
    mov eax, 4              ; sys_write
    mov ebx, 1              ; stdout
    mov ecx, buffer         ; user input
    mov edx, esi            ; length
    int 0x80

    ; Display newline
    mov eax, 4              ; sys_write
    mov ebx, 1              ; stdout
    mov ecx, newline        ; newline
    mov edx, newline_len    ; length
    int 0x80

    ; Exit program
    mov eax, 1              ; sys_exit
    xor ebx, ebx            ; exit code 0
    int 0x80
