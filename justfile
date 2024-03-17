start: 
    just asmembly
    just link
    just run
    just clean_build

# Run
run:
    # ./main test.asm
    ./main main.asm utils.asm -h

# Assembly
asmembly:
    nasm -f elf64 -o utils.o utils.asm
    nasm -f elf64 -o main.o main.asm

# Link
link:
    ld -o main utils.o main.o

# Compile, Link as Debug 
cld:
    nasm -f elf64 -g -F dwarf -o main.o main.asm
    nasm -f elf64 -g -F dwarf -o utils.o utils.asm
    ld -o main utils.o main.o

debug:
    just cld
    gdb main
# Clean Build Files
clean_build:
    rm -f main.o main
