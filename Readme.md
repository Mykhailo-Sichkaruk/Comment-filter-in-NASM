# Mykhailo Sichkaruk

## Specificaion
This programm is written for x86_64 processors and linux kernel.
 
## Overview

This documentation covers the implementation details and usage of a JSI (Just Significant Instructions) program developed by Mykhailo Sichkaruk. The program is designed to perform various operations on text files, including but not limited to, listing numbers of different character types, finding and replacing characters, and formatting text. It is intended for use on the Intel 386 platform under DOS using TASM.

## Features

- **Command Line Arguments**: The program accepts arguments from the command line to specify the input file(s) and the operation to be performed.
- **Help Option**: Using the `-h` switch displays information about the program and its usage.
- **Macro Usage**: The program utilizes macros for repetitive tasks, improving code readability and maintainability.
- **OS and BIOS Calls**: For operations like cursor setting, string listing, screen clearing, and file handling, appropriate OS or BIOS calls are used.
- **Large File Support**: The program can correctly handle files up to at least 64 kB in size, reading the file content into a buffer for processing.
- **Error Handling**: Error conditions, such as file open errors, are appropriately handled, with informative messages displayed to the user.

## File Structure

- **macro.asm**: Contains macro definitions used throughout the program.
- **Main Program Files**: Consist of the main assembly file (not explicitly named here) which includes the `macro.asm` file and contains the logic for handling command line arguments, performing the specified operations on the input file(s), and managing program flow.

## Key Components

### Buffers

- **File Content Buffer**: A 1MB buffer is allocated for reading the content of the input file(s). This buffer allows for processing files that exceed the typical 64kB limit.

### Procedures

#### `compare_str`
- **Purpose**: Compares two null-terminated strings.
- **Parameters**: `R8` (char* str1), `R9` (char* str2).
- **Returns**: `RAX` (bool) - `1` if strings are equal, `0` otherwise.

#### `strlen`
- **Purpose**: Calculates the length of a null-terminated string.
- **Parameters**: `R8` (char* str).
- **Returns**: `RAX` (int) - Length of the string.

#### `print_str_nt`
- **Purpose**: Prints a null-terminated string to STDOUT.
- **Parameters**: `R8` (char* str).

#### `print_newline`
- **Purpose**: Prints a newline character to STDOUT.

#### `print_line`
- **Purpose**: Prints a null-terminated string followed by a newline.
- **Parameters**: `R8` (char* str).

#### `open_file`
- **Purpose**: Opens a file for reading.
- **Parameters**: `R8` (char* filename).
- **Returns**: File handle (int) in `RAX`.

#### `read_file_buff`
- **Purpose**: Reads the content of a file into the buffer.
- **Parameters**: `R8` - File handle.

#### `print_file`
- **Purpose**: Prints the content of a file based on the `print_non_comments` flag.
- **Parameters**: `R8` (char* file_handle), `RAX` (bool is_reversed).

### Error Handling

- **File Open Error**: If a file cannot be opened, an error message is displayed, indicating the possible reasons (e.g., file does not exist, lack of read permissions).

### Bonus Features Implemented

- **Many Files Handling**: The program can handle multiple files as input.
- **Comments**: The source code includes comments for better understanding and maintenance.
- **External Procedure with Linkage**: Certain functionalities are implemented as external procedures and linked to the main program.
- **Files Over 64KB**: The program supports processing files larger than 64KB by utilizing a large buffer and efficient reading strategies.

## Usage

To use the program, compile the assembly code with TASM and run the resulting executable from the DOS command line, specifying the desired operation and input file(s) as arguments. Use the `-h` switch for help on command line options.

## Conclusion

This documentation provides an overview and detailed information on the structure and functionality of Mykhailo Sichkaruk's JSI program. The program's design emphasizes flexibility, error handling, and user interaction, making it a robust tool for file and text manipulation in a DOS environment.
