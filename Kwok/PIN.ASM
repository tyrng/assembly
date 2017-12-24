.model small
.stack 100
.data
	str db 6 dup ("0"), "$"

	str2 db 13, 10, "'c' - clear", 13, 10, "'x' - exit", 13, 10, "User>$"

	str3 db 13, 10, "Insert only 'c' and 'x'$", 13, 10

        inp db 6 dup (?)

	temp db 6 dup (?), "$"

	num db 0

	scan db ?

	col db 0

.code
main proc
        mov ax, @data
        mov ds, ax

    PRT:mov num, 05h
	
	xor dx, dx
	
	call cls

	mov col, 0h
	call cursor

	;---out 6x '0'	
	mov ah, 9
	lea dx, str
	int 21h

	;---loop 1
        mov cx, 6
	mov si, 0
	
     L1:
	;---reset cursor at 18:05		
	mov col, 5
	call cursor

	;---in 
	mov ah, 1
        int 21h

        mov temp[si], al

	mov ah, 2
	mov bh, 0
        mov dh, 18h
	mov dl, num
	int 10h	
	
	mov ah, 9
	lea dx, temp
	int 21h
	
	dec num
	inc si

        loop L1

	;---loop or exit
   COND:		

	mov ah, 9
	lea dx, str2 
	int 21h
	
	mov ah, 1
	int 21h
	
	mov scan, al
	
	cmp scan, "c"
	je SPC
	cmp scan, "x"
	je EXT

	;---continue mov inp, temp
	
	mov ah, 9
	lea dx, str3
	int 21h

	loop COND

    SPC:
	;---spacebar
	mov cx, 6
	mov si, 0
     L2:	
	mov al, 20h
	mov temp[si],al	
	inc si

	loop L2
	jmp PRT

    EXT:		
	;---terminate
        mov ah, 4ch
        int 21h
        main endp

cls proc
	mov ax, 0003h
    	int 10h 
	ret
cls endp

cursor proc 
	mov ah, 2
	mov bh, 0
        mov dh, 18h
	mov dl, col
	int 10h
	ret
cursor endp

end main
