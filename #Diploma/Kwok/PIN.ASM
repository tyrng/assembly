.model small
.stack 100
.data
	str db 6 dup ("0"), "$"     
	str2 db 13, 10, "'c' - clear"
	     db 13, 10, "'x' - exit"
	     db 13, 10, "User>$"   
	str3 db 13, 10, "Insert only 'c' and 'x'$", 13, 10
        inp db 6 dup (?)                           
	temp db 6 dup (?), "$"                            
	num db 0                                         
	scan db ? 

.code
main proc
        mov ax, @data
        mov ds, ax

    PRT:mov num, 5
	
	xor dx, dx
	
	call cls
	call cursor

	;---out 6x '0'	
	lea dx, str
	call print

	;---loop 1
        mov cx, 6
	mov si, 0
	
     L1:
	;---reset cursor at 18:05
	mov dl, 5			
	call cursor

	;---in 
	mov ah, 0
        int 16h

        mov temp[si], al

	mov dl, num
	call cursor
	
	lea dx, temp
	call print
	
	dec num
	inc si

        loop L1

	;---loop or exit
   COND:		
	lea dx, str2 
	call print
	
	mov ah, 1
	int 21h
	
	mov scan, al
	
	cmp scan, "c"
	je SPC
	cmp scan, "x"
	je EXT

	;---continue mov inp, temp
	
	lea dx, str3
	call print

	loop COND

    SPC:
	;---spacebar
	mov cx, 6
	mov si, 0
     L2:	
	mov temp[si], 20h	
	inc si     
	loop L2  
	
	jmp PRT

    EXT:		
        mov ah, 4ch
        int 21h
        main endp 
 
cls proc
	mov ax, 0003h
    	int 10h 
	ret      
	
cursor proc 
	mov ah, 2
	mov bh, 0
	mov dh, 16h
	int 10h 
	
	ret    

print proc
    mov ah, 9
    int 21h
    xor dx, dx 
    
    ret
end main
