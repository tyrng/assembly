.MODEL SMALL
.STACK 64
.DATA

num1 dw 0001H, 0678H
num2 dw 0000H, 9678H

ans dw 0000, 0000

.CODE
MAIN PROC
MOV AX,@DATA
MOV DS,AX
;================

subtract:
xor ax, ax
xor bx, bx
xor dx, dx

mov ax, num1[2]
mov bx, num2[2]
sub ax, bx
mov ans[2], ax

mov ax, num1
mov bx, num2
sbb ax, bx
mov ans, ax

;================
MOV AH,4CH
INT 21h
MAIN ENDP
END MAIN