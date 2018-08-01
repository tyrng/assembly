.MODEL SMALL
.STACK 64
.DATA

;GENERAL VARIABLES
num1 dw 0000H, 121d
num2 dw 0000H, 0000H


ans dw 0000H, 9999H

;POWER FUNCTION VARIABLES
pow_counter dw ?
pow_of dw 10
temp_pow dw 0, 0


;Division variables
tens    dw      10d, 100d, 1000d
rmdr    dw      ?
temp_rmdr dw    ?
temp_dp dw      0000h, 0000h
dp      db      0, 0


;ERROR MEESAGE STRINGS
err db 0
err_str1 db "SYNTAX ERROR!$",10,13,24


.CODE
MAIN PROC
MOV AX,@DATA
MOV DS,AX
;================

call power

;================
MOV AH,4CH
INT 21h
MAIN ENDP

ERROR_MSG PROC

mov ah, 09H
lea dx, err_str1
int 21H

ret 
ERROR_MSG ENDP

power PROC
;====================WELCOME TO THE POWER FUNCTION==============

;--ERROR CHECKING---
cmp ans[0], 0H
JNE ERROR_MSG
JNZ  pow_exit

;PRESETS FOR POWER LOOP

mov ax, num1[0]
mov bx, num1[2]

mov temp_pow[0], ax
mov temp_pow[2], bx

XOR CX, CX
MOV CX, pow_of		;SET LOOP COUNTER TO POWER OF X
SUB CX, 1

BIG_LOOP:
mov pow_counter, cx

;---POWER FORMULA---
POWER_CALC:

mov ax, num1[0]
mov bx, num1[2]

;===temp power===
mov ax, temp_pow[0]
mov bx, temp_pow[2]

mov num2[0], ax
mov num2[2], bx

call multiply

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

;===ROUND OFF 3rd and 4th decimal place===
pow_decimalRound:
mov ax, 0
mov bx, 10000d

mov num2[0], ax
mov num2[2], bx

call division

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

;===loop back power===

mov cx, pow_counter

cmp cx, 0
je pow_exit


loop BIG_LOOP


pow_exit:
 
ret 
power ENDP


addition PROC
xor ax, ax
xor bx, bx

mov ax, num1[2]
mov bx, num2[2]
add ax, bx

mov ans+2, ax
mov ax, num1
mov bx, num2
adc ax,bx

mov ans, ax   
   
ret 
addition ENDP

multiply PROC

xor ax, ax
xor bx, bx
xor cx, cx
xor dx, dx

mov ax, num1[2]
mul num2[2]
mov ans[2], ax
mov cx, dx

mov ax, num1
mul num2[2]
add cx, ax
mov bx, dx
jnc mul_move
add bx, 1H

mul_move:
mov ax, num1[2]
mul num2
add cx, ax
mov ans[0], cx
mov cx, dx

ret 
multiply ENDP

division PROC
;================

mov     cx, num2[2]                ;cx = dvsr
xor     dx,dx                  ;dx = 0
mov     ax, num1[0]    ;ax = high order numerator
div     cx                     ;dx = rem, ax = high order quotient
mov     ans[0], ax   ;store high order quotient
mov     ax, num1[2]      ;ax = low  order numerator
div     cx                     ;dx = rem, ax = low  order quotient
mov     ans[2], ax     ;store low  order quotient
mov     rmdr, dx     ;store remainder

;---CONVERT REMAINDER---
mov si, 0

cmp rmdr, 0
je divExit

div_check:
inc si

mov ax, rmdr
mul tens[0]

jc  cutDiv

conv_dp:
mov ax, rmdr
mul tens[0]

xor dx, dx
mov cx, num2[2]
div cx

mov rmdr, dx

cmp si, 1
je  bxMul

cmp si, 2
je  bxPlus
ja  cx_roundOff      
      
bxMul:
mul tens[0]
mov bx, ax
jmp div_check

bxPlus:
add bx, ax
jmp div_check

cx_roundOff:
cmp ax, 5
jae incBx

mov temp_rmdr, bx
jmp normal_div

incBx:
inc bx
mov temp_rmdr, bx
jmp normal_div      
      
;====
cutDiv:
xor dx, dx
mov ax, num2[2]
div tens[0]

mov num2[2], ax
mov cx, ax

xor dx, dx
mov ax, rmdr
div cx

mov rmdr, dx

cmp si, 1
je bxMul

cmp si, 2
je bxPlus
ja cx_roundOff

;--normal shiz
normal_div:

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

mov ax, 100
mov num2[2], ax

call multiply

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

mov ax, temp_rmdr
mov num2[2], ax

call addition

;---Dividend END POINT OF RECURSION---
cmp di, 0
je dp_checker
pop dx
jmp divExit

;---Decimal Point CHECKING---
dp_checker:         ;CHECK DP (DUH!)
mov ax, word ptr dp
xor ax, 0202h 
                 
cmp ax, 0000h
  jz divExit

cmp ax, 0202h
  je divExit
                                 
cmp ax, 0200h
  je dividend_dec	;Jump if dvidivend has decimal
  jne divisor_dec	;Jump if divisor has decimal


;dividend shiz
dividend_dec:

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

mov ax, 10000d
mov num2[2], ax 

mov di, 1
call division       ;======RECURSION!!!=======

;divisor shiz
divisor_dec:


jmp divExit

divExit:
ret

division ENDP

END MAIN