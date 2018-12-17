global _read_key
global _encrypt_text
global _decrypt_text
section .data
const_filename_plaintext db 'plaintext.txt', 0
const_filename_encryptedtext db 'encryptedtext.txt', 0
const_filename_decryptedtext db 'decryptedtext.txt', 0
const_message_for_user db 'Enter key (up to 20 symbols):', 10
const_len_message_for_user equ $ - const_message_for_user
const_asterisk db '*'
ICANON equ 1<<1
ECHO equ 1<<3
section .bss
termios resb 36
val_buffer resb 4096
val_key resb 21
val_len_key resb 4
val_tmp resb 2
val_ptr_file_plaintext resb 4
val_ptr_file_encryptedtext resb 4
val_ptr_file_decryptedtext resb 4
section .text
_start:
call _read_key
call _encrypt_text
call _decrypt_text
jmp _end
_read_key:
    mov eax, 4
    mov ebx, 1
    mov ecx, const_message_for_user
    mov edx, const_len_message_for_user
    int 0x80
    test eax, eax
    js _error_read_key
    call _turn_canonical_echo_off
    xor esi, esi
    _loop_read_key:
        cmp esi, 20
        ja _error_read_key_len
        mov eax, 3
        mov ebx, 0
        mov ecx, val_tmp
        mov edx, 1
        int 80h
        test eax, eax
        js _error_read_key
        mov al, byte [val_tmp]
        cmp al, 10
        je _end_loop_read_key
        cmp al, 97
        jb _read_key_check_next
        cmp al, 122
        ja _read_key_check_next
        sub al, 97
        jmp _read_key_check_end
        _read_key_check_next:
        cmp al, 65
        jb _error_read_key_wrong_symbol
        cmp al, 90
        ja _error_read_key_wrong_symbol
        sub al, 65
        _read_key_check_end:
        mov byte [val_key + esi], al
        mov eax, 4
        mov ebx, 1
        mov ecx, const_asterisk
        mov edx, 1
        int 80h
        test eax, eax
        js _error_read_key
        inc esi
        jmp _loop_read_key
    _end_loop_read_key:
    cmp esi, 0
    je _error_read_key_len
    mov dword [val_len_key], esi
    call _turn_canonical_echo_on
    ret
_encrypt_text:
    mov eax, 5
    mov ebx, const_filename_plaintext
    mov ecx, 0
    int 80h
    test eax, eax
    js _error_open_file
    mov dword [val_ptr_file_plaintext], eax
    mov eax, 5
    mov ebx, const_filename_encryptedtext
    mov ecx, 101q
    mov edx, 700q
    int 80h
    test eax, eax
    js _error_open_file
    mov dword [val_ptr_file_encryptedtext], eax
    xor esi, esi
    _loop_read_plaintext_file:
        mov eax, 3
        mov ebx, dword [val_ptr_file_plaintext]
        mov ecx, val_buffer
        mov edx, 4096
        int 80h
        test eax, eax
        js _error_read_file
        cmp eax, 0
        je _end_loop_read_plaintext_file
        mov ecx, eax
        _loop_encrypt_buffer:
            push eax
            mov ax, si
            mov bx, word [val_len_key]
            call _do_mod
            mov si, ax
            pop eax
            push eax
            xor edx, edx
            xor ebx, ebx
            xor edi, edi
            mov di, ax
            sub di, cx
            mov bl, byte [val_buffer + edi]
            cmp bl, 97
            jb _check_enc_next
            cmp bl, 122
            ja _check_enc_next
            mov dl, byte [val_key + esi]
            mov al, 97
            call _do_encrypt
            inc esi
            jmp _check_enc_end
            _check_enc_next:
            cmp bl, 65
            jb _check_enc_end
            cmp bl, 90
            ja _check_enc_end
            mov dl, byte [val_key + esi]
            mov al, 65
            call _do_encrypt
            inc esi
            _check_enc_end:
            pop eax
            xor edi, edi
            mov di, ax
            sub di, cx
            mov byte [val_buffer + edi], bl
        loop _loop_encrypt_buffer
        push eax
        mov edx, eax
        mov eax, 4
        mov ebx, dword [val_ptr_file_encryptedtext]
        mov ecx, val_buffer
        int 80h
        test eax, eax
        js _error_write_file
        pop eax
        cmp eax, 4096
        je _loop_read_plaintext_file
    _end_loop_read_plaintext_file:
    mov eax, 6
    mov ebx, dword [val_ptr_file_encryptedtext]
    int 80h
    mov eax, 6
    mov ebx, dword [val_ptr_file_plaintext]
    int 80h
    ret
_do_encrypt:
    sub bl, al
    add bl, dl
    push eax
    mov ax, bx
    mov bx, 26
    call _do_mod
    mov bl, al
    pop eax
    add bl, al
    ret
_decrypt_text:
    mov eax, 5
    mov ebx, const_filename_encryptedtext
    mov ecx, 0
    int 80h
    test eax, eax
    js _error_open_file
    mov dword [val_ptr_file_encryptedtext], eax
    mov eax, 5
    mov ebx, const_filename_decryptedtext
    mov ecx, 101q
    mov edx, 700q
    int 80h
    test eax, eax
    js _error_open_file
    mov dword [val_ptr_file_decryptedtext], eax
    xor esi, esi
    _loop_read_encryptedtext_file:
        mov eax, 3
        mov ebx, dword [val_ptr_file_encryptedtext]
        mov ecx, val_buffer
        mov edx, 4096
        int 80h
        test eax, eax
        js _error_read_file
        cmp eax, 0
        je _end_loop_read_encryptedtext_file
        mov ecx, eax
        _loop_decrypt_buffer:
            push eax
            mov ax, si
            mov bx, word [val_len_key]
            call _do_mod
            mov si, ax
            pop eax
            push eax
            xor edx, edx
            xor ebx, ebx
            xor edi, edi
            mov di, ax
            sub di, cx
            mov bl, byte [val_buffer + edi]
            cmp bl, 97
            jb _check_dec_next
            cmp bl, 122
            ja _check_dec_next
            mov dl, byte [val_key + esi]
            mov al, 97
            call _do_decrypt
            inc esi
            jmp _check_dec_end
            _check_dec_next:
            cmp bl, 65
            jb _check_dec_end
            cmp bl, 90
            ja _check_dec_end
            mov dl, byte [val_key + esi]
            mov al, 65
            call _do_decrypt
            inc esi
            _check_dec_end:
            pop eax
            xor edi, edi
            mov di, ax
            sub di, cx
            mov byte [val_buffer + edi], bl
        loop _loop_decrypt_buffer
        push eax
        mov edx, eax
        mov eax, 4
        mov ebx, dword [val_ptr_file_decryptedtext]
        mov ecx, val_buffer
        int 80h
        test eax, eax
        js _error_write_file
        pop eax
        cmp eax, 4096
        je _loop_read_encryptedtext_file
    _end_loop_read_encryptedtext_file:
    mov eax, 6
    mov ebx, dword [val_ptr_file_decryptedtext]
    int 80h
    mov eax, 6
    mov ebx, dword [val_ptr_file_encryptedtext]
    int 80h
    ret
_do_decrypt:
    sub bl, al
    add bl, 26
    sub bl, dl
    push eax
    mov ax, bx
    mov bx, 26
    call _do_mod
    mov bl, al
    pop eax
    add bl, al
    ret
_do_mod:
    xor dx, dx
    div bx
    mov ax, dx
    add ax, bx
    xor dx, dx
    div bx
    mov ax, dx
    ret
_error_read_key_len:
    call _turn_canonical_echo_on
    jmp _end
_error_read_key:
    call _turn_canonical_echo_on
    jmp _end
_error_read_key_wrong_symbol:
    call _turn_canonical_echo_on
    jmp _end
_error_open_file:
    jmp _end
_error_read_file:
    jmp _end
_error_write_file:
    jmp _end
_turn_canonical_echo_off:
    call _read_stdin_termios
    mov eax, ICANON
    or eax, ECHO
    not eax
    and [termios + 12], eax
    call _write_stdin_termios
    ret
_turn_canonical_echo_on:
    call _read_stdin_termios
    mov eax, ICANON
    or eax, ECHO
    or [termios + 12], eax
    call _write_stdin_termios
    ret
_read_stdin_termios:
    mov eax, 36h
    mov ebx, 0
    mov ecx, 5401h
    mov edx, termios
    int 80h
    ret
_write_stdin_termios:
    mov eax, 36h
    mov ebx, 0
    mov ecx, 5402h
    mov edx, termios
    int 80h
    ret
_end:
    mov eax, 1
    mov ebx, 0
    int 80h
