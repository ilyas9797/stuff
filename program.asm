
; Метки объявленные с директивой global являются глобальными.
; Глобальные метки нужны она для возможности написания многомодульных программ.
; Благодаря ним другие модули могут, ссылаясь на эту метку,
; исполнять строки кода из данного модуля (стр. 17).
; В данном случае мы объявляем метку "_start" как глобальную.
; Это необходимо, чтобы компилятор знал, где начинается программа.
global _start

; Секция статических данных (известных во время компиляции).
; В ней будут находить все данные известные до запуска программы,
; т.е. которые не будут изменяться во время работы программы.
; (подробнее стр. 9).
section .data

; const_filename_plaintext содержит имя файла, из которого 
; будет происходить считывание открытого текста (подробнее о db на стр. 7).
const_filename_plaintext db 'plaintext.txt', 0

; const_filename_encryptedtext содержит имя файла, в который 
; будет происходить запись шифртекста.
const_filename_encryptedtext db 'encryptedtext.txt', 0

; const_filename_decryptedtext содержит имя файла, в который 
; будет происходить запись расшифрованного текста.
const_filename_decryptedtext db 'decryptedtext.txt', 0

; const_message_for_user - сообщение пользователю, предлагающее ввести пароль
; число 10 обозначает переход на новую строку
const_message_for_user db 'Enter key (up to 20 symbols):', 10

; const_len_message_for_user - хранит длинну сообщения для пользователя
; $ - равен текущему адресу
const_len_message_for_user equ $ - const_message_for_user

const_asterisk db '*'

; Секция динамических данных (так называемая куча).
; В ней будут находить все переменные, используемые и определяемые
; во время работы программы (подробнее стр. 9).
section .bss

; val_buffer - переменная, указывающая на буфер для обработки данных.
; Принцип работы программы следующий:
; 1) Считываем до 4096 байтов текста из файла 'plaintext.txt'
;    в буфер val_buffer.
; 2) Шифруем текст в буфере.
; 3) Записываем шифртекст из буфера в файл 'encryptedtext.txt'.
; 4) Если на 1 шаге дошли до конца файла, то конец программы,
;    иначе возвращаемся к 1 шагу.
val_buffer resb 4096

; val_key - хранит ключ, максимальная длина которого - 20 байт, минимальная допустимая - 1
val_key resb 21
val_len_key resb 2

; val_tmp - временный буфер, в него, например, будем сохранять 
; по одному символу при вводе пароля
val_tmp resb 2

; val_ptr_file_plaintext - хранит указатель на файл с открытыми данными
val_ptr_file_plaintext resb 4

; val_ptr_file_encryptedtext - хранит указатель на файл с зашифрованными данными
val_ptr_file_encryptedtext resb 4

; val_ptr_file_decryptedtext - хранит указатель на файл с расшифрованными данными
val_ptr_file_decryptedtext resb 4

; к сожалению, пока это относится к магии
; termios resb 36

section .text

; Начало программы
_start:

; открытие файла с открытым текстом в режиме чтения

; создание и открытие файла с зашифрованным текстом в режиме записи

; считывание ключа
call _read_key

; чтение открытого тектса, его зашифрование и 
; запись зашифрованного текста в соответсвующий файл

jmp _end






; ------------------------------------------------------------------------------
; Функция, отвечающая за считывание ключа из командной строки
; Не принимает аргументов
; В случае успешного чтения ключа он будет записан в val_key, а в val_len_key его длинна
_read_key:

    ; Вывод сообщения пользователю
    ; Подробнее о том как работают функции считывания и записи в файл на стр. 10
    ; 4 - обозначает функцию записи
    ; ssize_t write(int fd, const void *buf, size_t count)
    mov eax, 4

    ; В регистр ebx нужно положить первый аргумент для функции write - "int fd",
    ; а именно указатель на файл записи. В данном случае 1, т.к. это
    ; указывает на то, что запись будет будет производиться на дисплей
    mov ebx, 1

    ; В регистр ecx кладем второй аргумент - буфер данных для записи
    mov ecx, const_message_for_user

    ; В edx кладем третий аргумент - количество записываемых символов
    mov edx, const_len_message_for_user

    ; Вызываем указанную функцию с указанными параметрами (подробнее стр. 6)
    int 0x80

    ; Если при вызове функции произошла ошибка,
    ; то в регистре eax будет отрицательное число.
    ; Для проверки eax используем функцию test (подробнее стр. 8)
    test eax, eax
    
    ; Если в eax появилось отрицательное число, то функция test установит 
    ; флаг sf в 1, и тогда сработает условный переход js, и программа 
    ; перейдет в блок обработки ошибки считывания ключа _error_read_key
    ; (подробнее об условных переходах стр. 4).
    js _error_read_key


; call    echo_off
; call    canonical_off
    
    ; обнуляем региср esi, он будет служить для хранения количества
    ; уже введеных пользователем символов
    xor si, si

    ; цикл для считывания пароля
    _loop_key_read:

        ; если количество введеных символов станет равным 21,
        ; значит пользователь превысил максимальную длину пароля
        cmp si, 21
        je _error_read_key_too_long

        ; Считывание пароля, будем считывать по 1 символу и 
        ; выводить звездочку на каждый символ
        ; 3 - обозначает функцию считывания
        ; ssize_t read(int fd, void *buf, size_t count)
        mov eax, 3
        
        ; В регистр ebx нужно положить первый аргумент для функции read - "int fd",
        ; а именно указатель на файл считывания. В данном случае 0, т.к. это
        ; указывает на то, что считывание будет происходить с клавиатруры
        mov ebx, 0
        
        ; В регистр ecx кладем второй аргумент - буфер для считанных данных
        mov ecx, val_tmp
        
        ; В edx кладем третий аргумент - количество считываемых символов
        mov edx, 1
        
        ; Вызываем указанную функцию с указанными параметрами (подробнее стр. 6)
        int 80h
        
        test eax, eax
        js _error_read_key

        mov al, byte [val_tmp]
        ; проверка того, что пользователь ввел Enter (символ перехода на новую строку)
        cmp al, 10
        je _end_loop_key_read
        
        ; Если в eax появился 0, значит пользователь не ввел ни одного 
        ; символа и нажал Enter. В таком случае тоже переходим в блок ошибки.
        ; Для проверки на ноль используем функцию cmp (стр. 4)
        cmp eax, 0
        jz _error_read_key

        ; если пользователь ввел не Enter, то записываем символ в буфер
        mov byte [val_key + esi], al

        ; Вывод звездочки на экран
        mov eax, 4
        mov ebx, 1
        mov ecx, const_asterisk
        mov edx, 1
        int 80h

        ; ошибка при выводе звездочки
        test eax, eax
        js _error_read_key

        ; увеличиваем текущую длинну пароля
        inc si

        jmp _loop_key_read

    ; конец цикла считывания ключа
    _end_loop_key_read:

    mov word [val_len_key], si

    ret

; ------------------------------------------------------------------------------







; ------------------------------------------------------------------------------
; Функция, отвечающая за открытие файла,
; принимает три аргумента 
;   через ebx - название файла,
;   через ecx - режим открытия файла
;   через edx - права на доступ к файлу
; возвращает один аргумент через eax - указатель на открытый файл
_open_file:
    ; 5 - обозначает функцию открытия файла (стр. 10)
    ; int open(const char *pathname, int flags)
    ; или
    ; int open(const char *pathname, int flags, mode__t mode)
    mov eax, 5
    
    ; Вызываем указанную функцию с указанными параметрами
    int 80h
    
    ; Проверяем, что функция open отработала без ошибки,
    ; т.е. проверяем положительное или отрицательное число лежит в eax
    test eax, eax
    
    ; Если в eax появилось отрицательное число, то сработает
    ; условный переход js, и программа перейдет в блок 
    ; обработки ошибки открытия файла с текстом _error_open_plaintext_file
    js _error_open_plaintext_file
    
    ret
; ------------------------------------------------------------------------------







; ------------------------------------------------------------------------------
; Функция шифрования текта. Общий принцип работы следующий:
; 1) Считывание до 4096 байтов из файла val_ptr_file_plaintext с открытым текстом в буфер val_buffer
; 2) Шифрование данных в буфере val_buffer ключем из val_key
; 3) Запись зашифрованных данных в файл val_ptr_file_encryptedtext
; 4) Если остались несчитанные данные в файле val_ptr_file_plaintext, возврат к пункту 1
_encrypt_text:

    
; ------------------------------------------------------------------------------


; Блок кода, отвечающий за запись шифр-текста в файл ""
_write_encrypted_text:

; Блок кода, отвечающий за обработку ошибки при слишком длином ключе
_error_read_key_too_long:

; Блок кода, отвечающий за обработку любых других ошибок при считывании ключа
_error_read_key:

; Блок кода, отвечающий за обработку ошибки считывания ключа
_error_open_plaintext_file:



; ------------------------------------------------------------------------------
; пока это все - магия
; canonical_off:
;  	call read_stdin_termios
; 	mov eax, 1
;    ; not eax
;     and [termios+12], eax

;     call write_stdin_termios
;     ret
            
; echo_off:
;     call read_stdin_termios
; 	mov eax, 7
;    ; not eax
;    	and [termios+12], eax

;    	call write_stdin_termios
;    	ret


; canonical_on:
;   	call read_stdin_termios
; 	or dword [termios+12], ICANON
; 	call write_stdin_termios
;     ret

; echo_on:
;     call read_stdin_termios
; 	or dword [termios+12], ECHO
; 	call write_stdin_termios
;     ret


; read_stdin_termios:
;     mov eax, 36h
;     mov ebx, 0
;     mov ecx, 5401h
;     mov edx, termios
;     int 80h
;     ret

; write_stdin_termios:
;     mov eax, 36h
;     mov ebx, 0
;     mov ecx, 5403h
;     mov edx, termios
;     int 80h
;     ret
; ------------------------------------------------------------------------------


_end:
    mov eax, 1
    mov ebx, 0
    int 80h