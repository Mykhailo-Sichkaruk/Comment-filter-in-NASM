	;       PERF: Axion: when we read file to the buffer, buffer all file is read at once
	section .bss

buffer:
	resb 0x10000; Kib

	section .data

print_non_comments:
	dq 0x0; Print non-comments flag

buffer_length:
	dq 0x10000; Kib

newline:
	db 0xA; New line character

newline_str:
	db 0xA, 0x0; New line character

file_open_error:
	db "File canont be opened, check whether file with such name exists, whether you have permission to read it", 0

error_message:
	db "Error", 0
	;  Place start of the first string to r8
	;  Place start of the second string to r9
	;  Consider null-terminated strings
	;  Place 1 in RAX if strings are equal, 0 otherwise

	section .text

compare_str:
	push r8; Save pointer to the first string
	push r9; Save pointer to the second string
	push rcx; Save byte from the first string
	push rdx; Save byte from the second string

iter:
	mov cl, byte [r8]; Load byte from the first string
	mov dl, byte [r9]; Load byte from the second string
	cmp cl, 0; Check if it is null-terminator
	je  equal_null_terminated; If yes, strings are equal
	cmp dl, 0; Check if it is null-terminator
	je  not_equal; If yes, strings are not equal
	cmp cl, dl; Compare bytes
	jne not_equal; If not equal, return 0
	inc r8; Move to the next byte in the first string
	inc r9; Move to the next byte in the second string
	jmp iter

equal_null_terminated:
	cmp dl, 0; Check if the second string is null-terminated
	je  equal; If yes, strings are equal
	jmp not_equal; If not, strings are not equal

equal:
	mov rax, 1
	jmp compare_str_end

not_equal:
	mov rax, 0
	jmp compare_str_end

compare_str_end:
	pop rdx; Restore rdx register that was used to save byte from the second string
	pop rcx; Restore rcx register that was used to save byte from the first string
	pop r9; Restore pointer to the second string
	pop r8; Restore pointer to the first string
	ret

	; NOTE: int print_buff_interval(char* left_p, char* right_p)
	; int strlen(char* str)
	; str - pointer to the start of the string must be placed in R8
	; consdier null-terminated string
	; return length of the string to the RAX register

strlen:
	push r8; Save pointer to the string
	push rcx; Save byte from the memory
	mov  rax, 0; Set length to 0

strlen_iter:
	mov cl, byte [r8]; Load byte from the memory
	cmp cl, 0; Check if it is null-terminator
	je  strlen_end; If yes, return
	inc rax; If not, increment length
	inc r8; Move to the next byte
	jmp strlen_iter; Repeat

strlen_end:
	pop rcx; Restore rcx register that was used to save byte from the memory
	pop r8; Restore pointer to the string
	ret

	; NOTE: void print_str_nt(char* str)
	; str - pointer to the start of the string must be placed in R8
	; print null-terminated string to the stdout

print_str_nt:
	push    rdx; save RDX
	push    rax; save rax
	push    rdi
	push    rsi
	push    rcx
	call    strlen; Get length of the string
	mov     rdx, rax; Move length to the RDX register
	mov     rax, 1; WRITE syscall
	mov     rdi, 1; set STDOUT as the file descriptor
	mov     rsi, r8; Prepare pointer to the string
	syscall ; Print the string
	pop     rcx
	pop     rsi
	pop     rdi
	pop     rax
	pop     rdx
	ret

print_newline:
	push rdx; save RDX
	push rax; save rax
	push rdi; save rdi
	push rsi; save rsi
	push rcx; save rcx
	mov  rdi, 1; STDOUT
	mov  rsi, newline; New line character
	mov  rdx, 1; Length of the string
	mov  rax, 1; WRITE syscall
	syscall
	pop  rcx
	pop  rsi
	pop  rdi
	pop  rax
	pop  rdx
	ret

	; NOTE: void print_line(char* str)
	; str - pointer to the start of the string must be placed in R8
	; print null-terminated string to the stdout and print new line

print_line:
	call print_str_nt
	call print_newline
	ret

exit:
	mov     rax, 60; system call for exit
	xor     rdi, rdi; exit code 0
	syscall ; invoke operating system to exit
	ret

	; NOTE: Open file|  int* open(char* file_name). Also prints
	; r8: char* - file name [PARAM]
	; rax: int  - file handle [RETURN]

open_file:
	push rdi; save rdi
	push rsi; save rsi
	push rdx; save rdx
	push rcx; save rcx
	mov  rax, 2; open syscall
	mov  rdi, r8; file name
	mov  rsi, 0; read only
	mov  rdx, 0; mode set
	syscall
	cmp  rax, 0; check if file was opened
	jl   open_file_error; if not, print error message
	jmp  open_file_end; if yes, return file handle

open_file_error:
	call print_line; print file name
	mov  r8, file_open_error; set error message
	call print_line; print error message
	jmp  open_file_end

open_file_end:
	pop rcx; restore rcx
	pop rdx; restore rdx
	pop rsi; restore rsi
	pop rdi; restore rdi
	ret

	; NOTE: Read file content to the `buffer`
	; [PARAM] R8 - file handle

read_file_buff:
	push rdi; save rdi
	push rsi; save rsi
	push rdx; save rdx
	push rcx; save rcx
	mov  rax, 0; read syscall
	mov  rdi, r8; file handle
	mov  rsi, buffer; buffer
	mov  rdx, [buffer_length]; buffer size
	syscall
	pop  rcx; restore rcx
	pop  rdx; restore rdx
	pop  rsi; restore rsi
	pop  rdi; restore rdi
	ret

	; NOTE: Print file
	; [PARAM] r8: char* - file handle
	; [PARAM] rax: bool - is_reversed; 0 - print non-commented strings, 1 - print commented strings
	; WARN: We assume that we read all file content to the buffer at once

print_file:
	mov  [print_non_comments], rax; set print_non_comments flag
	call read_file_buff;; rax = read buffer size
	push r8; save r8
	mov  r8, buffer; set start of the string
	mov  r9, rax; set length of the string
	call print_buff_no_comments; print the buffer
	pop  r8; restore r8
	ret

	; NOTE: Print buffer with/without comments
	; [PARAM] rax: int buff_len_param    - length of the `buffer`
	; [LOCAL] r11: bool is_comment - is comment met
	; [LOCAL] r12: bool is_slash   - is `/` met
	; [LOCAL] r13: *char left_p    - relative laft_pointer
	; [LOCAL] r14: *char right_p   - relative right_p
	; [LOCAL] bl: char c          - current byte
	; [LOCAL] rdi: int buff_len    - length of the `buffer` (not the capacity)

print_buff_no_comments:
	;   iterate over the buffer untill the `#`, `/` or `; `  is met
	mov rdi, rax; buff_len = buff_len_param
	mov r11, 0; is_comment = false
	mov r12, 0; is_slash = false
	mov r13, 0; left_p = 0
	mov r14, 0; right_p = 0

pbnc_iter:
	mov bl, byte [buffer + r14]; c = buffer[rish_p]
	cmp bl, 24h; c === `#`
	je  comment_found
	cmp bl, 3Bh; c === `; `
	je  comment_found
	cmp bl, 2Fh; c === `/`
	je  slash_found
	cmp bl, 0Ah; c === `\n`
	je  pbnc_newline
	cmp r14, rdi; right_p === buffer_length
	jge pbnc_file_end
	inc r14; else
	jmp pbnc_iter

pbnc_file_end:
	;cmp r11, 0; is_comment == true
	;je  pbnc_print_buff
	ret

pbnc_newline:
	;    if previous interval was a non-commented string and `-r` not set, print it, else do nothing
	;    print_non_comments XOR is_comment
	push rax; save rax
	mov  rax, r11; tmp = is_comment
	xor  rax, [print_non_comments]; tmp ^= print_non_comments
	xor  rax, 1; tmp ^= 1
	cmp  rax, 1; tmp === 0
	pop  rax; restore rax
	jne  pbnc_newline_skip; skip interval
	call print_buff_interval; print interval
	call print_newline; print new line
	jmp  pbnc_newline_ret

pbnc_newline_skip:
	jmp pbnc_newline_ret

pbnc_newline_ret:
	;   else
	cmp r14, rdi; right_p === buffer_length
	je  pbnc_ret
	mov r13, r14; left_p = right_p
	inc r14; right_p++
	mov r12, 0; is_slash = false
	mov r11, 0; is_comment = false
	;   Check whether this is the end of the buffer. buffer_length - 1 === right_p

	jmp pbnc_iter

	; NOTE: Print buffer from `left_p` to `right_p`
	; [PARAM] r13: char*  - left_p
	; [PARAM] r14: char*  - right_p

print_buff_interval:
	push r8; save r8
	push r9; save r9
	push rax; save rax
	;mov r8, buffer + r13
	lea  r8, [buffer + r13]; char * print_start = buffer + left_p
	mov  rax, r14; int len = right_p
	sub  rax, r13; len -= left_p
	mov  r9, rax; int len_param = len
	call print_str; print_str(print_start, len_param)
	pop  rax; restore rax
	pop  r9; restore r9
	pop  r8; restore r8
	ret

pbnc_ret:
	ret

	; print not commented string

pbnc_print_buff:
	call print_buff_interval; print_comment(left_p, right_p, to_print)
	jmp  pbnc_ret

slash_found:
	cmp r12, 0; is_slash === false
	je  first_slash_found
	mov r12, 0; if this is 2 slash in a row, then it is not a comment
	jmp comment_found

first_slash_found:
	mov r12, 1
	jmp pbnc_iter

	; if comment is found, print the string and set is_comment to true

comment_found:
	push rax; save rax
	mov  rax, r11; tmp = is_comment
	xor  rax, [print_non_comments]; tmp ^= print_non_comments
	xor  rax, 1; tmp ^= 1
	cmp  rax, 1; tmp === 0
	pop  rax; restore rax
	jne  comment_found_skip; skip interval
	;    else; then previous interval was a non-commented string, print it
	call print_buff_interval; print_comment(left_p, right_p, to_print)
	mov  r11, 1; is_comment = true
	inc  r14; right_p++
	mov  r11, 1; is_comment = true
	mov  r13, r14; left_p = right_p
	jmp  pbnc_iter

comment_found_skip:
	inc r14; right_p++
	mov r13, r14; left_p = right_p
	mov r11, 1; is_comment = true
	jmp pbnc_iter

	; NOTE: Print string (char* str, int len)
	; [PARAM] r8: char* - pointer to the string
	; [PARAM] r9: int   - length of the string

print_str:
	push    rdx; save RDX
	push    rax; save rax
	push    rdi; save rdi
	push    rsi; save rsi
	push    rcx; save rcx
	mov     rax, 1; WRITE syscall
	mov     rdi, 1; set STDOUT as the file descriptor
	mov     rsi, r8; Prepare pointer to the string
	mov     rdx, r9; set length of the string
	syscall ; Print the string
	cmp     rax, -1; fd == -1
	je      print_str_error; if yes, print error message
	pop     rcx; restore rcx
	pop     rsi; restore rsi
	pop     rdi; restore rdi
	pop     rax; restore rax
	pop     rdx; restore RDX
	ret

print_str_error:
	mov  r8, error_message
	call print_line

	global compare_str
	global print_line
	global exit
	global print_file
	global open_file
	global print_str_nt
	global print_newline
