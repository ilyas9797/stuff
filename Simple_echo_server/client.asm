section .data
  socket_error      db   'TCP-client: socket() error', 0x0a 
  socket_er_len     equ  $-socket_error
  conn_error        db   'TCP-client: connect() error', 0x0a 
  conn_er_len       equ  $-conn_error
  buffer_len        equ  1024
  please_write      db   0x0a, '============================', 0x0a, 'Enter your message to server:', 0x0a
  please_write_len  equ  $-please_write
  sever_message     db   'Server messaged you:', 0x0a
  sever_message_len equ  $-sever_message
  connection_closed     db 'Server closed connection! Exit...', 0x0a
  connection_closed_len equ  $-connection_closed

section .bss
  buffer:          resb 1024
  socket:          resd 1
  connection:      resd 1
  socket_address:  resd 1
  read_count:      resd 1
  reading_cycles:  resd 1


section .text
global _start
_start:


  ; syscalls (/usr/include/asm/unistd_32.h) - заголовочный файл, в котором содержатся номера системных вызовов (прерываний)
	; socketcall numbers (/usr/include/linux/net.h) - заголовочный файл, в котором содержатся номера функций, вызываемых системным вызовом socketcall

_socket:
  ; аргументы функции - int socket(int domain, int type, int protocol)
  ; http://man7.org/linux/man-pages/man2/socket.2.html
  push  0                 ; protocol = 0 - протокол по умолчанию для выбранного domain
  push  1                 ; type = SOCK_STREAM - TCP
  push  2                 ; domain = AF_INET - IPv4 Internet protocols
  ; вызов функции socket - создаем сокета
  ; вызов происходит через системное прерывание sys_socketcall с указанием номера вызываемой функции
  ; http://man7.org/linux/man-pages/man2/socketcall.2.html
  ; Номера функций: https://people.cs.clemson.edu/~westall/853/notes/udpsock.pdf
  mov  eax, 102                 ; номер системного вызова sys_socketcall
  mov  ebx, 1                   ; номер функции socket
  mov  ecx, esp					        ; указатель на список аргументов - указывает на вершину стека
  int  0x80
  cmp  eax, 0                   ; eax содержит дескриптор сокета
  jb   sock_err					        ; если после вызова eax < 0, значит произошла ошибка при создании сокета
  mov  dword [socket], eax    	; сохраняем дескриптор сокета в переменной socket



_connect:
  ; создание структуры sockaddr_in для функции connect и заполнение ее полей:
  ;   sockaddr_in.sin_family
  ;   sockaddr_in.sin_port
  ;   sockaddr_in.sin_addr
  ; http://textarchive.ru/c-2490286-p14.html
  ; mov  word [socket_address], 2         ; sin_family = AF_INET - IPv4 Internet protocols
  ; mov  word [socket_address + 2], 6666  ; sin_port = 170 - номер порта 
  ; mov  eax, [in_addr]
  ; mov  [socket_address + 4], eax        ; sin_addr = INADDR_ANY - любой IP-адрес
  push  0       		    ; sin_addr = INADDR_ANY - любой IP-адрес
  push  word  0x0a0a            ; sin_port = 170 - номер порта 
  push  word  2                 ; sin_family = AF_INET - IPv4 Internet protocols
  mov   [socket_address], esp 	; копируем структуру sockaddr_in по адресу [socket_address]
  ; аргументы функции - int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
  ; http://man7.org/linux/man-pages/man2/connect.2.html
  push  16            			      ; addrlen - размер структуры sockaddr в байтах. Небольшая хитрость - мы заполнили лишь 8 байт структуры sockaddr_in, которые поместили по адресу [socket_address], т.к. остальные 8 байт структуры sockaddr_in определяются полем sin_zero и не используются.
  push  dword [socket_address]
  push  dword [socket]       	    ; sockfd - указатель на дескриптор созданного сокета socket
  ; вызов функции connect - подключаемся к серверу
  mov  eax, 102                 ; номер прерывания sys_socketcall 
  mov  ebx, 3                   ; номер функции connect
  mov  ecx, esp                 ; указатель на список аргументов - указывает на вершину стека
  int  0x80
  cmp  eax, 0                   ; eax = 0 в случае успешного вызова bind
  jb   conn_err                 ; если после вызова eax < 0, значит произошла ошибка при привязки адреса сокету


reading_writing:

  ; вывод подсказки о вводе сообщения для сервера
  ; ssize_t write(int fd, const void *buf, size_t count)
  mov  eax, 4          	       ; номер системного вызова функции write
  mov  ebx, 1                  ; параметр fd - дескриптор потока стандартного вывода
  mov  ecx, please_write       ; параметр buf - приглашение на ввод
  mov  edx, please_write_len ; параметр count - максимальное число считанных символов
  int  0x80


  ; считывание сообщения пользователя из командной строки вызовом read
  ; ssize_t read(int fd, void *buf, size_t count)
  mov  eax, 3                   ; номер системного вызова функции read
  mov  ebx, 0                   ; параметр fd - дескриптор потока стандартного ввода
  mov  ecx, buffer              ; параметр buf - буфер для сохранения считано сообщения
  mov  edx, buffer_len          ; параметр count - максимальное число считанных символов
  int  0x80
  mov  dword [read_count], eax   ; сохраняем размер считанного сообщения


  ; отправка сообщеия пользователя серверу вызовом write
  ; ssize_t write(int fd, const void *buf, size_t count)
  mov  eax, 4          	     ; номер системного вызова функции write
  mov  ebx, [socket]         ; параметр fd - дескриптор сокета
  mov  ecx, buffer           ; параметр buf - считаное сообщение
  mov  edx, [read_count]     ; параметр count - максимальное число считанных символов
  int  0x80


  ; считывание полученного от сервера сообщения системным вызовом read
  ; ssize_t read(int fd, void *buf, size_t count)
  mov  eax, 3                   ; номер системного вызова функции read
  mov  ebx, [socket]            ; параметр fd - дескриптор сокета принятого соединения
  mov  ecx, buffer              ; параметр buf - буфер для сохранения считано сообщения
  mov  edx, buffer_len          ; параметр count - максимальное число считанных символов
  int  0x80
  mov  dword [read_count], eax   ; сохраняем размер считанного сообщения

  ; условие прекращения работы клиента - если было получено пустое сообщение
  cmp  eax, 1     ; в eax будет записано количество считанных символов
  je   exit         ; если длинна полученного сообщения 0, то завершаем программу


  ; вывод подсказки о полученном от сервера сообщения
  ; ssize_t write(int fd, const void *buf, size_t count)
  mov  eax, 4          	        ; номер системного вызова функции write
  mov  ebx, 1                   ; параметр fd - дескриптор потока стандартного вывода
  mov  ecx, sever_message       ; параметр buf - приглашение на ввод
  mov  edx, sever_message_len ; параметр count - максимальное число считанных символов
  int  0x80


  ; вывод полученного от севера сообщения на экран
  ; ssize_t write(int fd, const void *buf, size_t count)
  mov  eax, 4          	       ; номер системного вызова функции write
  mov  ebx, 1                  ; параметр fd - дескриптор потока стандартного вывода
  mov  ecx, buffer       ; параметр buf - приглашение на ввод
  mov  edx, [read_count] ; параметр count - максимальное число считанных символов
  int  0x80

jmp reading_writing
  

exit:
  ; вывод подсказки о закрытии соединения
  ; ssize_t write(int fd, const void *buf, size_t count)
  mov  eax, 4          	            ; номер системного вызова функции write
  mov  ebx, 1                       ; параметр fd - дескриптор потока стандартного вывода
  mov  ecx, connection_closed       ; параметр buf - приглашение на ввод
  mov  edx, connection_closed_len ; параметр count - максимальное число считанных символов
  int  0x80

  mov  eax, 6                 ; sys_close
  mov  ebx, [socket]
  int  0x80
  jmp _exit


sock_err:
  mov  ecx, socket_error
  mov  edx, socket_er_len
  jmp _write_err 

conn_err:
  mov  ecx, conn_error
  mov  edx, conn_er_len
  jmp _write_err 

_write_err: 	; вывод ошибок
  mov  eax, 4
  mov  ebx, 2
  int 0x80

_exit:
  mov  eax, 1
  mov  ebx, 0
  int 0x80