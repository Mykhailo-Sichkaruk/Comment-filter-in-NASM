	;        function calling convention - RBP, RBX, R12, R13, R14, R15 are callee-saved
	;        RDI, RSI, RDX, RCX, R8, R9, XMM0-XMM7 are caller-saved
	%include "macro.asm"

	section .data

help_msg:
	db "Usage: ./print_file [file1] [file2] ...", 10, "Prints the content of the files to the console without comments", 10, "Options:", 10, "  -r: Print only comments", 10, "  -h: Show this message", 10, 0

no_args_found_msg:
	db "No arguments found", 10, 0

reverse_flag_found_msg:
	db "-r is found", 10, 0

reverse_flag_not_found_msg:
	db "-r is not found", 10, 0

help_flag:
	db "-h", 0

reverse_flag:
	db "-r", 0

is_reversed:
	dq 0; 1 - print 

comment_1:
	db "#", 0

argc:
	dq 0

argv_p:
	dq 0

	global  _start
	extern  print_line
	extern  open_file
	extern  compare_str
	extern  exit
	extern  print_file
	extern  print_str_nt
	extern  print_newline
	%define print_line print_line

	section .text

	; NOTE:
	; [PARAM] r9: char* argv_fing

find_flag:
	save_regs  rcx, rdx, r14
	mov rcx, [argc]; argc
	mov rdx, [argv_p]; *argv
	add rdx, 8; argv_p++; Skip the first argument argv[0] - program name
	dec rcx; argc-- Skip the first argument argv[0] - program name
	cmp rcx, 0; argc == 0
	je  .flag_not_found
	mov r14, [rdx]; current argument

.find_flag_body:
	mov  r8, r14; R8 = argv[x]
	call compare_str; rax = strcmp(argv[x], "-r")
	cmp  rax, 1; rax === 1
	je   .flag_found
	jmp  .find_flag_update

.find_flag_condition:
	cmp rcx, 0; argc == 0
	je  .flag_not_found
	jmp .find_flag_body

.find_flag_update:
	dec rcx; argc--
	add rdx, 8; argv_p++
	mov r14, [rdx]; current argument
	jmp .find_flag_condition

.flag_found:
	mov rax, 1
	restore_regs rcx, rdx, r14
	ret

.flag_not_found:
	mov rax, 0
	restore_regs rcx, rdx, r14
	ret

	; NOTE:: This function checks if -r argument is present in the program arguments
	; WARN: [ASSUMPTION] that argc and argv_p are saved in global variables argc and argv_p
	; PERF: [RETURN]: RAX; 1 there is -r argument, 0 otherwise

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
	add rdx, 8; argv_p++; Skip the first argument argv[0] - program name
	dec rcx; argc--; Skip the first argument argv[0] - program name
	cmp rcx, 0; argc == 0
	je  no_args_found
	mov r14, [rdx]; current argument

iofn_body:
	mov  r8, r14; R8 = argv[x]
	mov  r9, reverse_flag; R9 = "-r"
	call compare_str; rax = strcmp(argv[x], "-r")
	cmp  rax, 1; rax == 0
	je   iofn_update; if argv[x] == "-r" then
	call process_file
	jmp  iofn_update

iofn_condition:
	cmp rcx, 0; argc == 0
	je  finish_iterate_over_files
	jmp iofn_body

iofn_update:
	dec rcx; argc--
	add rdx, 8; argv_p++
	mov r14, [rdx]; current argument
	jmp iofn_condition

	; NOTE: Process files - print name, open, print content according to the task
	; [PARAM] R8 = file name
	; [RETURN] RAX = 0 if file is not found, 1 otherwise

process_file:
	call print_newline
	call print_str_nt
	call print_newline
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

	; Entry point
	; [PARAM] RDI = argc
	; [PARAM] RSI = *argv
	; [RETURN] RAX = 0

_start:
	pop  rdi; argc
	mov  [argc], rdi; argc = argc
	mov  [argv_p], rsp; argv_p = *argv
	mov  r9, help_flag
	;    if (find("-h") === 1) help_flag_found()
	call find_flag
	cmp  rax, 1
	je   help_flag_found
	call is_reverse_flag
	call iterate_over_files
	call exit

help_flag_found:
	mov  r8, help_msg
	call print_line
	call exit

	; is_reverse db 0; 1 if -r is present, 0 otherwise
	; My task is to print files listed in program arguments to the consodle, skipping comments like `#`, ` // ` and `/* */`
	; 1 - find -r argument
	; 2 - iterate over each argument
	; 2.1 - try to open a file
	; 2.2 - if file is not found, print error message and continue
	; 2.3 - if file is found, read it line by line
