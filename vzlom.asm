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

            mov cx, BUFFER_SIZE
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
;Arguments: CX = max number of bytes to read, DX = address of buffer to receive data, BX = standart input device handle
;Return value: DX = offset 'output_message'
;Destroy: ES, AX, CX, SI, DI
;-------------------------------------------------------------------------------------------------------
CheckInput          proc

                    mov ah, 3fh
                    int 21h                     ; Read file, AX = number of bytes actually read

                    cld                         ; Clear direction flag to up
                    mov si, dx
                    mov di, offset CorrectPassword
                    mov cx, ax
                    push ds
                    pop es
                    call CheckPassword

                    ret
                    endp

;-------------------------------------------------------------------------------------------------------
;Compares InputBuffer and CorrectPassword. Output FailureMessage or SuccessMessage to console.
;Arguments: DF = 0 (for SI++ and DI++), ES = DS, CX = number of bytes to read, SI and DI = cmp strings offsets
;Return value: DX = offset 'output_message'
;Destroy: AX, CX, SI, DI
;-------------------------------------------------------------------------------------------------------
CheckPassword       proc

                    repe cmpsb              ; while (CX != 0 && ZF == 0) SI++ DI++; (cmp DS:[SI] and  ES:[DI])
                    jne @@IfWrongPassword     ; ZF == 1 => difference found

                    mov ah, 09h
                    mov dx, offset SuccessMessage
                    int 21h
                    jmp @@AfterMessage

@@IfWrongPassword:  mov ah, 09h
                    mov dx, offset FailureMessage
                    int 21h

@@AfterMessage:     ret
                    endp
;-------------------------------------------------------------------------------------------------------

BUFFER_SIZE     equ 4096

RequestStr      db 'Please, enter password', 0dh, 0ah, '$'
InputBuffer     db 4096 dup(?)

SuccessMessage  db 'Access granted', 0dh, 0ah, '$'
FailureMessage  db 'Access denied', 0dh, 0ah, '$'

CorrectResult   dd 'NP8#E%v203jaa24', 0dh

EndOfProgram:
end         Start
