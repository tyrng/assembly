.model small
.stack 100
.data
	ARRAY LABEL BYTE
	MAX DB 9
	ACT DB ?
	INPUT DB 9 DUP (0)
	
	str1 db "Input here >> $"
	str2 db 13, 10, "Output here >> $"

	num db 2
	Q db 0
	ten db 0Ah

	OUTPUT DB 9 DUP (?), "$"
	
.code
main proc
	mov ax, @data
	mov ds, ax

	mov ah, 9
	lea dx, str1
	int 21h

	mov ah, 0Ah
	lea dx, ARRAY
	int 21h


	mov ah, 9
	lea dx, str2
	int 21h

;-----------------------------------------------------

	mov cl, ACT
	mov si, cx
L1:
	xor ax, ax
	mov al, INPUT[si-1]

	cmp al, "."
	JE SKIP

	sub al, 30h
	mul num
	add al, Q
	div ten

	add ah, 30h
	mov OUTPUT[si-1], ah

	mov Q, al

BACK:
	dec si
	loop L1	

	jmp OUTP

SKIP:
	mov bl, "."
	mov OUTPUT[si-1], bl
	xor bx, bx
	jmp BACK

OUTP:
	mov ah, 9
	lea dx, OUTPUT
	int 21h

	mov ah, 4ch
	int 21h	
main endp

end main
