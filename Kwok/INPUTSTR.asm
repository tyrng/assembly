.model small
.stack 100
.data
	ARRAY LABEL BYTE
	MAX DB 5
	ACT DB ?
	INPUT DB 5 DUP (0)	 
	
	str1 db "Enter Loan amount (0-5000) : $"
	str db "Err msg here $"   
	
	MULTI dw 1h, 10h, 100h, 1000h
	STORE dw ?, "$"
.code
main proc
	mov ax, @data
	mov ds, ax
                
    call loanInput
                
	mov ah, 4ch
	int 21h	
main endp 

print proc
    mov ah, 9
    int 21h
                
    ret
    
loanInput proc
    lea dx, str1      
    call print
    
    mov ah, 0Ah
    lea dx, ARRAY
    int 21h      
    
    xor cx, cx
    xor bx, bx   
    
    mov cl, act
    mov si, cx    
    mov di, 0
L1:              
    xor ax, ax
    xor dx, dx
    
    mov al, INPUT[si-1]
    sub al, 30h
    
    mul MULTI[di]      ;dec ==> hex computation 
    
    add ax, dx 
    mov STORE, ax              
    
    dec si  
    inc di  
    
    loop L1  
    
    lea dx, STORE    ;remove delimiter for calculation
    call print
                       
    ret
               
end main                   
