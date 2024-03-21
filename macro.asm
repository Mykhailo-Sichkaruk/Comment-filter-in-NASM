%macro save_regs 0-6  ; Allows between 0 to 5 parameters
    %ifidn %1, %1     ; Check if the first parameter exists
        push %1
    %endif
    %ifidn %2, %2     ; Check if the second parameter exists
        push %2
    %endif
    %ifidn %3, %3     ; Check if the third parameter exists
        push %3
    %endif
    %ifidn %4, %4     ; Check if the fourth parameter exists
        push %4
    %endif
    %ifidn %5, %5     ; Check if the fifth parameter exists
        push %5
    %endif
    %ifidn %6, %6     ; Check if the sixth parameter exists
        push %6
    %endif
%endmacro

%macro restore_regs 0-6  ; Matches save_regs in terms of parameter count
    %ifidn %6, %6     ; Check if the sixth parameter exists
        pop %6
    %endif
    %ifidn %5, %5     ; Check if the fifth parameter exists
        pop %5
    %endif
    %ifidn %4, %4     ; Check if the fourth parameter exists
        pop %4
    %endif
    %ifidn %3, %3     ; Check if the third parameter exists
        pop %3
    %endif
    %ifidn %2, %2     ; Check if the second parameter exists
        pop %2
    %endif
    %ifidn %1, %1     ; Check if the first parameter exists
        pop %1
    %endif
%endmacro

