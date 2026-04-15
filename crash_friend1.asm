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
            mov cx, 37h
            inc cx

            mov dx, offset FileBuffer
            int 21h

            ret
            endp

;-------------------------------------------------------------------------------------------------------

FileBuffer db 36h dup (00h) 
           db 1 dup (0dh)

EndOfProgram:
end         Start
