.model small
.stack 100
.data
	ARRAY LABEL BYTE
	MAX DB 9
	ACT DB ?
	INPUT DB 9 DUP (0)
	
	str1 db "Input here >> $"
	str2 db 13, 10, "Output here >> $"

	R db 0
	ten db 0Ah
	hundred db 64h            
	two dw 2

	OUTPUT DB 10 DUP (?), "$"
	
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
                          
    xor cx, cx 
    
	mov cl, ACT
	mov si, cx
L1:
	xor ax, ax     
			
	mov al, INPUT[si-1]
	sub al, 30h 
	
	cmp si, 1
	JE FLOAT       
	
BACK:
	div hundred
	
	add ah, 30h
	mov OUTPUT[si], ah                   
                         
	dec si

	loop L1      
    
    	jmp OUTP
    

FLOAT:
	mov bl, "."
	mov OUTPUT[si], bl
	
	dec si        
       
	jmp BACK  
	

OUTP:
	mov ah, 9
	lea dx, OUTPUT
	int 21h

	mov ah, 4ch
	int 21h	
main endp

end main
