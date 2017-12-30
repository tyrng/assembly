.model small
.stack 100
.data
    menu db "Bank Loan Machine$"
    menu1 db "1. Loan$" 
    menu2 db "2. Exit Program$"  
    string db "This is loan$"
	
	row db 0Eh                             
	                               	                               
.code
main proc
	mov ax, @data
	mov ds, ax    
    
    call _menuScreen
                
    mov ah, 4ch
    int 21h                     
main endp     
                   
_print proc  
    mov ah, 9
    int 21h
    
    ret                   
             
_color proc
    mov ax, 0920h       ;color focus      
    mov dl, 16h         ;col : 24d
    mov cx, 0017
    int 10h 
    
    ret

_cursor proc
    mov ah, 2           ;next cursor
    mov dl, 16h         ;col : 24d
    mov bh, 0  
    int 10h
    
    ret   
            
_menuScreen proc 
        mov ax, 0200h       ;set cursor to middle     
    mov bh, 0000        ;page 0
    mov dx, 0D16h       ;center
    int 10h
    
    ;set background color here  
             
    lea dx, menu        ;print menu
    call _print    

    
    xor dx, dx
                   
    mov dh, row        ;set row to 14 
    call _cursor
                                        
    mov bx, 00F0h         
    call _color  
    
                            
L1:              
    mov dh, 0Eh
    call _cursor  
    
    lea dx, menu1
    call _print 
               
    mov dh, 0Fh              
    call _cursor
    
    lea dx, menu2
    call _print         

            
    mov ah, 0
    int 16h  
           
    mov dh, row
    call _cursor
                         
    cmp al, "w"         ;arrow key selection
    je UP          
    cmp al, "s"
    je DOWN      
    cmp al, 0Dh
    je ENTER
    cmp al, "x"
    je EXIT      
    
                                                        
B1:       
    loop L1  
      
    
UP:           
    mov bx, 000Fh      ;set color back to normal
    call _color
    
    dec row        ;E - 1 = D
    
    mov bl, 0Dh    ;D
    cmp row, bl
    je U_RESET    ;D => F

U_BACK:    
    mov dh, row
    call _cursor     
    
    mov bx, 00F0h         
    call _color
    
    jmp B1      
              
U_RESET:    
    add row, 2         ;go back to bottom
    jmp U_BACK     
      
      
      
DOWN:                        
    mov bx, 000Fh   ;set color back to normal
    call _color
            
    inc row        
    
    mov bl, 10h    ;condition
    cmp row, bl
    je D_RESET  ;reset cursor
         
D_BACK:    
    mov dh, row
    call _cursor    
                
    mov bx, 00F0h
    call _color                                      

    jmp B1 
          
D_RESET:
    sub row, 2         ;go back to top
    jmp D_BACK                  
      
;--------------------------------------------------------          
EXIT:
    ret

ENTER:
    cmp row, 0Eh
    je LOAN_FUNC
    cmp row, 0Fh         ;to be added more menu selection
    je EXIT
    
    jmp B1           
           
LOAN_FUNC:          ;you can move this to your function   
    xor dx, dx
    
    mov ax, 0003   
    int 10h

    lea dx, string
    call _print
    
_menuScreen endp
                
end main
