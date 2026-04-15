.model tiny
.code
org 100h

;-------------------------------------------------------------------------------------------------------
Start:      call Main

            mov ax, 4c00h       ; Terminate
            int 21h

;-------------------------------------------------------------------------------------------------------

Main        proc

            mov ah, 40h
            mov bx, 1h
            mov cx, 0fc86h

            mov dx, offset FileBuffer
            int 21h

            ret
            endp

;-------------------------------------------------------------------------------------------------------

FileBuffer db 0fc83h dup (00h), 39h, 01h, 0dh

EndOfProgram:
end         Start
