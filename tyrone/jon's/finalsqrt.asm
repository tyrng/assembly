.MODEL SMALL
.STACK 64
.DATA

int32 dd 4H

squareRoot dw ?

num1 dw 5h, 5555h

ans dw 0 ,0

.CODE
MAIN PROC
MOV AX,@DATA
MOV DS,AX
;================

sqrt:

mov ax, num1[0]
mov bx, num1[2]

mov word ptr int32, bx
mov word ptr int32 + 2, ax

fild int32        ;load the integer to ST(0)
fsqrt             ;compute square root and store to ST(0)
fistp squareRoot  ;store the result in memory (as a 32-bit integer) and pop ST(0)

mov ax, word ptr squareRoot
mov ans[2], ax
mov bx, 0
mov ans[0], bx

;================
MOV AH,4CH
INT 21h
MAIN ENDP
END MAIN