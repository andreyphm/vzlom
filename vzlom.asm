.model tiny
.code
org 100h

;-------------------------------------------------------------------------------------------------------
Start:      call Main

            mov ax, 4c00h       ; Terminate
            int 21h

;-------------------------------------------------------------------------------------------------------

Main        proc

            xor bx, bx
            call PasswordRequest

            xor cx, cx
            dec cx
            mov dx, offset InputBuffer
            call CheckInput

            ret
            endp

;-------------------------------------------------------------------------------------------------------
;Asks for the password in the console
;Arguments: BX = standart input device handle
;Return value: DX = offset RequestStr
;Destroy: AX, DX
;-------------------------------------------------------------------------------------------------------
PasswordRequest         proc        

                        mov ax, 4400h
                        int 21h         ; Used to see if standart input has been redirected (First bit in DL)

                        and dl, 80h
                        cmp dl, 80h
                        jne @@IfInputRedirected

                        mov ah, 09h
                        mov dx, offset RequestStr
                        int 21h

@@IfInputRedirected:    ret
                        endp

;-------------------------------------------------------------------------------------------------------
;Read from destination file, check password. Output FailureMessage or SuccessMessage to console.
;Arguments: CX = max number of bytes to read, DX = address of buffer to receive data
;Return value: DX = offset 'output_message', BX = offset of buffer with code
;Destroy: ES, AX, CX, SI, DI
;-------------------------------------------------------------------------------------------------------
CheckInput          proc

                    call ReadFile

                    mov cx, ax
                    cld                         ; Clear direction flag to up
                    call InputToStack

                    mov cx, ax                  ; Number of cycles = number of symbols in input
                    sub ax, 1                   ; AX = last number of index in InputBuffer
                    xor di, di
                    mov bx, dx

                    call EncryptPassword

                    mov si, dx
                    mov di, offset CorrectResult
                    push ds
                    pop es
                    mov cx, CORRECT_LENGTH
                    call CheckPassword

                    ret
                    endp

;-------------------------------------------------------------------------------------------------------
;Copy input buffer to stack.
;Arguments: DF = 0 (for SI++ and DI++), ES = DS, CX = max number of bytes to copy
;Return value: -
;Destroy: CX, SI, DI
;-------------------------------------------------------------------------------------------------------
InputToStack        proc

                    sub sp, 8192                ; Allocate memory for buffer in stack
                    mov di, sp                  ; DI = stack buffer address
                    mov si, offset InputBuffer
                    rep movsb
                    add sp, 8192

                    ret
                    endp

;-------------------------------------------------------------------------------------------------------
;Read file to input buffer.
;Arguments: BX = file handle, CX = max number of bytes to read, DX = address of buffer to receive data
;Return value: AX = number of bytes actually read
;Destroy: -
;-------------------------------------------------------------------------------------------------------
ReadFile            proc

                    mov ah, 3fh
                    int 21h

                    ret
                    endp

;-------------------------------------------------------------------------------------------------------
;Encrypt password: XOR buffer[i] with buffer[i-1] (firstly buffer[0] with last buffer element)
;Arguments: CX = number of elements in buffer, AX = last number of index in buffer, DI = 0, BX = address of buffer
;Return value: BX = address of buffer with hash
;Destroy: AX, SI, DI, CX
;-------------------------------------------------------------------------------------------------------
EncryptPassword     proc

@@Cycle:            mov si, di
                    test di, di 
                    je @@Cycle_2
                    sub si, 1
                    mov al, [bx + si]
                    xor [bx + di], al
                    inc di
                    loop @@Cycle
                    jmp @@Next

@@Cycle_2:          mov si, ax
                    mov al, [bx + si]
                    xor [bx + di], al
                    inc di
                    loop @@Cycle

@@Next:             ret
                    endp

;-------------------------------------------------------------------------------------------------------
;Compares InputBuffer and CorrectResult. Output FailureMessage or SuccessMessage to console.
;Arguments: DF = 0 (for SI++ and DI++), ES = DS, CX = number of bytes to compare, SI and DI = cmp strings offsets
;Return value: DX = offset 'output_message'
;Destroy: AX, CX, SI, DI
;-------------------------------------------------------------------------------------------------------
CheckPassword       proc

                    repe cmpsb                  ; while (CX != 0 && ZF == 0) SI++ DI++; (cmp DS:[SI] and  ES:[DI])
                    jne @@IfWrongPassword       ; ZF == 1 => difference found

                    mov ah, 09h
                    mov dx, offset SuccessMessage
                    int 21h
                    jmp @@AfterMessage

@@IfWrongPassword:  mov ah, 09h
                    mov dx, offset FailureMessage
                    int 21h

@@AfterMessage:     mov ah, 02h
                    xor di, di

                    ret
                    endp

;-------------------------------------------------------------------------------------------------------

CORRECT_LENGTH equ 15

RequestStr      db 'Please, enter password', 0dh, 0ah, '$'

SuccessMessage  db 'Access granted', 0dh, 0ah, '$'
FailureMessage  db 'Access denied', 0dh, 0ah, '$'

InputBuffer     db 4096 dup(?)
CorrectResult   db 67h, 0eh, 5dh, 35h, 74h, 1fh, 70h, 26h, 47h, 2bh, 74h, 31h, 47h, 4ah, 40h

EndOfProgram:
end         Start
