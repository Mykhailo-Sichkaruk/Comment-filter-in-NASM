	; PERF: Axion: when we read file to the buffer, buffer all file is read at once

	%include "macro.asm"

	section .bss

	; NOTE: 1MB buffer

buffer:
	resb 0x100000; Buffer for the file content

	section .data

print_non_comments:
	dq 0x0; 0 - print non-commented strings, 1 - print commented strings

	; NOTE: 1MB buffer length

buffer_length:
	dq 0x100000; Buffer length

newline:
	db 0xA; New line character

newline_str:
	db 0xA, 0x0; New line character

file_open_error:
	db "File canont be opened, check whether file with such name exists, whether you have permission to read it", 0

error_message:
	db "Error", 0

	section .text

	; NOTE: bool compare_str(char* str1, char* str2)
	; WARN: [PARAM] R8: char* str1 - pointer to the first string
	; WARN: [PARAM] R9: char* str2 - pointer to the second string
	; WARN: [LOCAL] CL: char c1    - byte from the first string
	; WARN: [LOCAL] DL: char c2    - byte from the second string
	; WARN: [RETURN] RAX: bool     - 1 - strings are equal, 0 - strings are not equal

compare_str:
	save_regs r8, r9, rcx, rdx

iter:
	mov cl, byte [r8]; c1 = *str1
	mov dl, byte [r9]; c2 = *str2
	cmp cl, 0; c1 === 0
	je  equal_null_terminated; If yes, strings are equal
	cmp dl, 0; c2 === 0
	je  not_equal; If yes, strings are not equal
	cmp cl, dl; c1 === c2
	jne not_equal; If not equal, return 0
	inc r8; str1++
	inc r9; str2++
	jmp iter

equal_null_terminated:
	cmp dl, 0; c2 === 0
	je  equal; If yes, strings are equal
	jmp not_equal; If not, strings are not equal

equal:
	mov rax, 1; retrun 1
	jmp compare_str_end

not_equal:
	mov rax, 0; return 0
	jmp compare_str_end

compare_str_end:
	restore_regs r8, r9, rcx, rdx
	ret

	; NOTE: int strlen(char* str)
	; WARN: [PARAM] R8:   char* str   - pointer to the start of the string
	; WARN: [LOCAL] CL:   char c      - byte from the memory
	; WARN: [RETURN] RAX: int len     - length of the string

strlen:
	save_regs r8, rcx
	mov rax, 0; len = 0

strlen_iter:
	mov cl, byte [r8]; c = *str
	cmp cl, 0; c === 0
	je  strlen_end; If yes, return
	inc rax; len++
	inc r8; str++
	jmp strlen_iter; Repeat

strlen_end:
	restore_regs r8, rcx
	ret

	; NOTE: Print null-terminated string
	; NOTE: void print_str_nt(char* str)
	; WARN: [PARAM] R8: char* str - pointer to the start of the string

print_str_nt:
	save_regs rdx, rax, rdi, rsi, rcx
	call    strlen; Get length of the string
	mov     rdx, rax; Move length to the RDX register
	mov     rax, 1; WRITE syscall
	mov     rdi, 1; set STDOUT as the file descriptor
	mov     rsi, r8; Prepare pointer to the string
	syscall ; Print the string
	restore_regs rdx, rax, rdi, rsi, rcx
	ret

	; NOTE: Print newline character

print_newline:
	save_regs rdx, rax, rdi, rsi, rcx
	mov rdi, 1; STDOUT
	mov rsi, newline; New line character
	mov rdx, 1; Length of the string
	mov rax, 1; WRITE syscall
	syscall
	restore_regs rdx, rax, rdi, rsi, rcx
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
	save_regs rdi, rsi, rdx, rcx
	mov rax, 2; open syscall
	mov rdi, r8; file name
	mov rsi, 0; read only
	mov rdx, 0; mode set
	syscall
	cmp rax, 0; check if file was opened
	jl  open_file_error; if not, print error message
	jmp open_file_end; if yes, return file handle

open_file_error:
	call print_line; print file name
	mov  r8, file_open_error; set error message
	call print_line; print error message
	jmp  open_file_end

open_file_end:
	restore_regs rdi, rsi, rdx, rcx
	ret

	; NOTE: Read file content to the `buffer`
	; [PARAM] R8 - file handle

read_file_buff:
	save_regs rdi, rsi, rdx, rcx
	mov rax, 0; read syscall
	mov rdi, r8; file handle
	mov rsi, buffer; buffer
	mov rdx, [buffer_length]; buffer size
	syscall
	restore_regs rdi, rsi, rdx, rcx
	ret

	; NOTE: Print file
	; NOTE: void print_file(char * file_handle, bool is_reversed)
	; WARN: [PARAM] r8: char* file_handle - file handle
	; WARN: [PARAM] rax: bool - is_reversed; 0 - print non-commented strings, 1 - print commented strings
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
	; WARN: [PARAM] rax: int buff_len_param    - length of the `buffer`
	; WARN: [LOCAL] r11: bool is_comment - is comment met
	; WARN: [LOCAL] r12: bool is_slash   - is `/` met
	; WARN: [LOCAL] r13: *char left_p    - relative laft_pointer
	; WARN: [LOCAL] r14: *char right_p   - relative right_p
	; WARN: [LOCAL] bl: char c          - current byte
	; WARN: [LOCAL] rdi: int buff_len    - length of the `buffer` (not the capacity)

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
	mov  rax, r11; tmp = is_comment
	cmp  rax, 1; tmp === 1
	jne  pbnc_newline_ret
	call print_newline; print newline
	jmp  pbnc_newline_ret

pbnc_newline_skip:
	jmp  pbnc_newline_ret

pbnc_newline_ret:
	;   else
	cmp r14, rdi; right_p === buffer_length
	je  pbnc_ret
	mov r13, r14; left_p = right_p
	inc r14; right_p++
	mov r12, 0; is_slash = false
	mov r11, 0; is_comment = false
	jmp pbnc_iter

pbnc_ret:
	ret

	; NOTE: void print_buff_interval(char* left_p, char* right_p)
	; NOTE: Print buffer from `left_p` to `right_p`
	; WARN: [PARAM] r13: char*  - left_p
	; WARN: [PARAM] r14: char*  - right_p

print_buff_interval:
	save_regs r8, r9, rax, r13, r14, r11
	lea  r8, [buffer + r13]; char * print_start = buffer + left_p
	mov  rax, r14; int len = right_p
	sub  rax, r13; len -= left_p
	mov  r9, rax; int len_param = len
	call print_str; print_str(print_start, len_param)
	restore_regs r8, r9, rax, r13, r14, r11
	ret

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
	; WARN: [PARAM] r8: char* str - pointer to the string
	; WARN: [PARAM] r9: int len  - length of the string

print_str:
	save_regs rdx, rax, rdi, rsi, rcx
	mov     rax, 1; WRITE syscall
	mov     rdi, 1; set STDOUT as the file descriptor
	mov     rsi, r8; Prepare pointer to the string
	mov     rdx, r9; set length of the string
	syscall ; Print the string
	cmp     rax, -1; fd == -1
	je      print_str_error; if yes, print error message
	restore_regs rdx, rax, rdi, rsi, rcx
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
