	;         function calling convention - RBP, RBX, R12, R13, R14, R15 are callee-saved
	;         RDI, RSI, RDX, RCX, R8, R9, XMM0-XMM7 are caller-saved
	;%include "utils.asm"

	%macro save_registers 0
	push   rbx
	push   rbp
	push   r12
	push   r13
	push   r14
	push   r15
	%endmacro
	%macro restore_registers 1
	pop    r15
	pop    r14
	pop    r13
	pop    r12
	pop    rbp
	pop    rbx
	%endmacro

	global  _start
	extern  print_line
	extern  open_file
	extern  compare_str
	extern  exit
	extern  print_file
	%define print_line print_line

	section .text

	; Assume that argc and argv_p are saved in global variables argc and argv_p
	; RETURN: RAX = 1 there is -r argument, 0 otherwise

is_reverse_flag:
	mov rcx, [argc]; argc
	mov rdx, [argv_p]; *argv
	add rdx, 8; argv_p++
	dec rcx; argc--
	cmp rcx, 0; argc == 0
	je  reverse_flag_not_found
	mov r14, [rdx]; current argument

is_reverse_flag_iter:
	mov  r8, r14
	mov  r9, reverse_flag
	call compare_str
	cmp  rax, 1
	je   reverse_flag_found
	dec  rcx; argc--
	cmp  rcx, 0; argc == 0
	je   reverse_flag_not_found
	add  rdx, 8; argv_p++
	mov  r14, [rdx]; current argument
	jmp  is_reverse_flag_iter

reverse_flag_found:
	mov  r8, reverse_flag_found_msg
	call print_line
	mov  [is_reversed], byte 1
	ret

reverse_flag_not_found:
	mov  r8, reverse_flag_not_found_msg
	call print_line
	mov  [is_reversed], byte 0
	ret

	; Assume that argc and argv_p are saved in global variables argc and argv_p
	; Iterate over each argument and call print_file_content for each file

iterate_over_files:
	mov rcx, [argc]; argc
	mov rdx, [argv_p]; *argv
	add rdx, 8; argv_p++; Skip the first argument argv[0]
	dec rcx; argc--; Skip the first argument argv[0]
	cmp rcx, 0; argc == 0
	je  no_args_found
	mov r14, [rdx]; current argument

iterate_over_file_names:
	mov  r8, r14; R8 = argv[x]
	mov  r9, reverse_flag; R9 = "-r"
	call compare_str; rax = strcmp(argv[x], "-r")
	cmp  rax, 1; rax == 1
	jne  process_file; true: skip this argument
	dec  rcx; argc--
	add  rdx, 8; argv_p++
	mov  r14, [rdx]; current argument
	jmp  iterate_over_file_names

process_file:
	call open_file
	mov  r8, rax
	mov  rax, [is_reversed]
	call print_file
	ret

no_args_found:
	mov  r8, no_args_found_msg
	call print_line
	ret

finish_iterate_over_files:
	ret

_start:
	pop  rdi; argc
	mov  [argc], rdi; argc = argc
	mov  [argv_p], rsp; argv_p = *argv
	call is_reverse_flag
	call iterate_over_files
	call exit

	section .data

no_args_found_msg:
	db "No arguments found", 10, 0

reverse_flag_found_msg:
	db "-r is found", 10, 0

reverse_flag_not_found_msg:
	db "-r is not found", 10, 0

reverse_flag:
	db "-r", 0

is_reversed:
	dq 0; 1 if -r is present, 0 otherwise

comment_1:
	db "#", 0

argc:
	dq 0

argv_p:
	dq 0

	; is_reverse db 0; 1 if -r is present, 0 otherwise
	; My task is to print files listed in program arguments to the consodle, skipping comments like `#`, ` // ` and `/* */`
	; 1 - find -r argument
	; 2 - iterate over each argument
	; 2.1 - try to open a file
	; 2.2 - if file is not found, print error message and continue
	; 2.3 - if file is found, read it line by line
