section .data
  socket_error      db   'TCP-server: socket() error', 0x0a 
  socket_er_len     equ  $-socket_error
  bind_error        db   'TCP-server: bind() error', 0x0a 
  bind_er_len       equ  $-bind_error
  listen_error      db   'TCP-server: listen() error', 0x0a 
  listen_er_len     equ  $-listen_error
  accept_error      db   'TCP-server: accept() error', 0x0a 
  accept_er_len     equ  $-accept_error
  buffer_len        equ  1024
  in_addr           db   0x7f, 0x00, 0x00, 0x01

section .bss
  buffer:          resb 1024
  socket:          resd 1
  connection:      resd 1
  socket_address:  resd 4
  read_count:      resd 1
  reading_cycles:  resd 1


section .text
global _start
_start:


  ; аргументы функции - int socket(int domain, int type, int protocol)
  ; http://man7.org/linux/man-pages/man2/socket.2.html
  push  0                 ; protocol = 0 - протокол по умолчанию для выбранного domain
  push  1                 ; type = SOCK_STREAM - TCP
  push  2                 ; domain = AF_INET - IPv4 Internet protocols

  ; вызов функции socket - создаем сокета
  ; вызов происходит через системное прерывание sys_socketcall с указанием номера вызываемой функции
  ; http://man7.org/linux/man-pages/man2/socketcall.2.html
  ; Номера функций: https://people.cs.clemson.edu/~westall/853/notes/udpsock.pdf
  mov  eax, 102                 ; номер прерывания sys_socketcall
  mov  ebx, 1                   ; номер функции socket
  mov  ecx, esp					        ; указатель на список аргументов - указывает на вершину стека
  int  0x80
  cmp  eax, 0                   ; eax содержит дескриптор сокета
  jb   sock_err					        ; если после вызова eax < 0, значит произошла ошибка при создании сокета
  mov  dword [socket], eax    	; сохраняем дескриптор сокета по адресу [socket]
  
  pop
  pop
  pop

  ; создание структуры sockaddr_in для функции connect и заполнение ее полей:
  ;   sockaddr_in.sin_family
  ;   sockaddr_in.sin_port
  ;   sockaddr_in.sin_addr
  ; http://textarchive.ru/c-2490286-p14.html
  mov  word [socket_address], 2         ; sin_family = AF_INET - IPv4 Internet protocols
  mov  word [socket_address + 2], 6666  ; sin_port = 170 - номер порта 
  mov  eax, [in_addr]
  mov  [socket_address + 4], eax        ; sin_addr = INADDR_ANY - любой IP-адрес
  ; push  0               		    ; sin_addr = INADDR_ANY - любой IP-адрес
  ; push  word  0xaa              ; sin_port = 170 - номер порта 
  ; push  word  2                 ; sin_family = AF_INET - IPv4 Internet protocols
  ; mov   [socket_address], esp 	; копируем структуру sockaddr_in по адресу [socket_address]

  ; аргументы функции - int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
  ; http://man7.org/linux/man-pages/man2/connect.2.html
  push  16            			      ; addrlen - размер структуры sockaddr в байтах. Небольшая хитрость - мы заполнили лишь 8 байт структуры sockaddr_in, которые поместили по адресу [socket_address], т.к. остальные 8 байт структуры sockaddr_in определяются полем sin_zero и не используются.
  push socket_address
  ; push  dword [socket_address]    ; addr - указатель на структура адреса socket_address
  push  dword [socket]       	    ; sockfd - указатель на дескриптор созданного сокета socket

  ; вызов функции connect - подключаемся к серверу
  mov  eax, 102                 ; номер прерывания sys_socketcall 
  mov  ebx, 3                   ; номер функции connect
  mov  ecx, esp                 ; указатель на список аргументов - указывает на вершину стека
  int  0x80
  cmp  eax, 0                   ; eax = 0 в случае успешного вызова bind
  jb   connect_err              ; если после вызова eax < 0, значит произошла ошибка при привязки адреса сокету

  pop
  pop
  pop

input:
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
  mov  ebx, [socket]
  mov  ecx, buffer
  mov  edx, [read_count]
  int  0x80

  

