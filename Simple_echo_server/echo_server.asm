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
  ; stop_word         db   'stop', 0x0a
  ; stop_word_len     equ  $-stop_word
  ; bye_msg           db   'session is over', 0x0a
  ; bye_msg_len       equ  $-bye_msg

section .bss
  accept_socket:   resd 1
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
  
  ; создание структуры sockaddr_in для функции bind и заполнение ее полей:
  ;   sockaddr_in.sin_family
  ;   sockaddr_in.sin_port
  ;   sockaddr_in.sin_addr
  ; http://textarchive.ru/c-2490286-p14.html
  mov  word  [socket_address], 2        ; sin_family = AF_INET - IPv4 Internet protocols
  mov  word  [socket_address + 2], 6666 ; sin_port = 170 - номер порта 
  mov  dword [socket_address + 4], 0    ; sin_addr = INADDR_ANY - любой IP-адрес
  ; push  0               		    ; sin_addr = INADDR_ANY - любой IP-адрес
  ; push  word  0xaa              ; sin_port = 170 - номер порта 
  ; push  word  2                 ; sin_family = AF_INET - IPv4 Internet protocols
  ; mov   [socket_address], esp 	; копируем структуру sockaddr_in по адресу [socket_address]

  ; аргументы функции - int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
  ; http://man7.org/linux/man-pages/man2/bind.2.html
  push  16            			      ; addrlen - размер структуры sockaddr в байтах. Небольшая хитрость - мы заполнили лишь 8 байт структуры sockaddr_in, которые поместили по адресу [socket_address], т.к. остальные 8 байт структуры sockaddr_in определяются полем sin_zero и не используются.
  push socket_address
  ; push  dword [socket_address]    ; addr - указатель на структура адреса socket_address
  push  dword [socket]       	    ; sockfd - указатель на дескриптор созданного сокета socket

  ; вызов функции bind - связываем сокет с адресом
  mov  eax, 102                 ; номер прерывания sys_socketcall 
  mov  ebx, 2                   ; номер функции bind
  mov  ecx, esp                 ; указатель на список аргументов - указывает на вершину стека
  int  0x80
  cmp  eax, 0                   ; eax = 0 в случае успешного вызова bind
  jb   bind_err                 ; если после вызова eax < 0, значит произошла ошибка при привязки адреса сокету

  pop
  pop
  pop

  ; аргументы функции - int listen(int sockfd, int backlog)
  ; http://man7.org/linux/man-pages/man2/listen.2.html
  push  1						        ; backlog - размер очереди
  push  dword [socket]			; sockfd - дескриптор сокета

  ; вызов функции listen - создание очереди ожидание и перевод сокета в режим только прослушивание
  mov  eax, 102                 ; номер прерывания sys_socketcall 
  mov  ebx, 4                   ; номер функции listen
  mov  ecx, esp                 ; указатель на список аргументов - указывает на вершину стека
  int  0x80
  cmp  eax, 0                   ; eax = 0 в случае успешного вызова listen
  jb   listen_err               ; если после вызова eax < 0, значит произошла ошибка 

  pop
  pop
  
  accept_loop:
    ; аргументы функции - int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen)
    ; http://man7.org/linux/man-pages/man2/accept.2.html
    push  0						        ; addrlen - длинна структуры, возвращаемой параметром addr [необязательный параметр]
    push  0						        ; addr - после вызова структура будет содержать адрес и номер порта клиента [необязательный параметр]
    push  dword [socket]			; sockfd - дескриптор сокета, находящегося в режиме прослушивания

    ; вызов функции accept - прием запроса от клиента, а конкретнее, создание нового сокета, работающего в режиме чтения-записи
    mov  eax, 102                   ; номер прерывания sys_socketcall
    mov  ebx, 5                     ; номер функции accept
    mov  ecx, esp                   ; указатель на список аргументов - указывает на вершину стека
    int  0x80
    cmp  eax, 0					
    jb   accept_err
    mov  dword [accept_socket], eax ; сохраняем новый дескриптор сокета созданного вызовом функции accept

    pop
    pop
    pop
  
  
  mov  dword [reading_cycles], 0    ; переменная хранит число циклов считывания
  reading:
    ; считывание переданого сообщения системным вызовом read
    ; ssize_t read(int fd, void *buf, size_t count)
    mov  eax, 3                   ; номер системного вызова функции read
    mov  ebx, [accept_socket]     ; параметр fd - дескриптор сокета принятого соединения
    mov  ecx, buffer              ; параметр buf - буфер для сохранения считано сообщения
    mov  edx, buffer_len          ; параметр count - максимальное число считанных символов
    int  0x80
    
    ; условие выхода
    cmp  eax, 0                  ; в eax будет записано количество считанных символов
    jnz  continue_cycle          ; если было передано пусто сообщение, то завершаем программу
    mov  eax, [reading_cycles]   ; если это первый цикл считывания
    cmp  eax, 0
    jnz  continue_cycle    

    close_sock:
      mov  eax, 6           ; номер системного вызова функции close
      mov  ebx, [socket]
      int  0x80

    jmp  exit

    continue_cycle:

    mov  dword [read_count], eax   ; сохраняем размер считанного сообщения

    ; запись считанного сообщения обратно клиенту вызовом write
    ; ssize_t write(int fd, const void *buf, size_t count)
    mov  eax, 4          	     ; номер системного вызова функции write
    mov  ebx, [accept_socket]
    mov  ecx, buffer
    mov  edx, [read_count]
    int  0x80

    mov  eax, [reading_cycles]
    add  eax, 1
    mov  [reading_cycles], eax

    ; loop child						; снова переход на чтение
    loop reading            ; снова переход на чтение, если ecx не равен 0

  mov  eax, 6                 	; номер системного вызова функции close 
  mov  ebx, [accept_socket]     ; закрываем сокет принятого соединения
  int  0x80

  jmp  accept_loop


exit:
  mov  eax, 6                 ; sys_close
  mov  ebx, [accept_socket]
  int  0x80
  jmp _exit

sock_err:
  mov  ecx, socket_error
  mov  edx, socket_er_len
  jmp _write_err 

bind_err:
  mov  ecx, bind_error
  mov  edx, bind_er_len
  jmp _write_err 

listen_err:
  mov  ecx, listen_error
  mov  edx, listen_er_len
  jmp _write_err 

accept_err:
  mov  ecx, accept_error
  mov  edx, accept_er_len
  jmp _write_err 

_write_err: 	; вывод ошибок
  mov  eax, 4
  mov  ebx, 2
  int 0x80

_exit:
  mov  eax, 1
  mov  ebx, 0
  int 0x80
