.model small
.stack 100
.data                                
    ;LOGIN---------------------------
    loginstr db "Enter pass code $"
    
    ARRAY LABEL BYTE
    max db 20
    act db ?
    pass db 10 dup("$")                 
    
    password db "eewhore"          ;shhh...
    
    errorstr db "Pass code doesn't match!$"

    ;MENU ---------------------------
    menu db "Bank Loan Machine$"
    menu1 db "1. Loan$" 
    menu2 db "2. Exit Program$"  
    string db "This is loan$"
	  dos box doesnt recognise 1ch as enter        
	arrow db ?          ;this stores input of arrow  
	enter db ?          ;this stores input of enter                           
	row db 0Eh                             
	                               	                               
.code
main proc
	mov ax, @data
	mov ds, ax    
                     
    call _login                    
    call _menu 
EXIT:                
    mov ah, 4ch
    int 21h                     
main endp  

cls proc
    mov ax, 0003h
    int 10h         
    xor ax,ax
          
    ret
                   
print proc  
    mov ah, 9
    int 21h    
    xor dx,dx
        
    ret                   
             
color proc
    mov ax, 0920h       ;color focus      
    mov dl, 16h         ;col : 24d
    mov cx, 0017
    int 10h 
    
    ret

cursor proc    
    mov ah, 2           ;next cursor
    mov dl, 16h         ;col : 24d
    mov bh, 0  
    int 10h
    
    ret    
    
center_screen proc
    mov ax, 0200h       ;set cursor to middle     
    mov bh, 0           ;page 0
    mov dx, 0D16h       ;center
    int 10h
 
    ret       
       
_login proc     
L1:
    call cls
    
    mov dh, 0Dh
    call cursor                      
                          
    lea dx, loginstr
    call print 
                 
    mov dh, 0Eh
    call cursor
    
    mov bx, 00F0h
    call color  
    
    mov dh, 0Eh
    call cursor
                 
    mov ah, 0Ah           
    lea dx, ARRAY
    int 21h  
             
    xor cx, cx
    mov cx, 7       ;change this as well when you change password 
    mov si, 0             
L2:
    mov bl, password[si]
    cmp pass[si], bl
    jne L1
    
    loop L2    
    
    ret     
            
_menu proc 
    call center_screen
    ;set background color here  
             
    lea dx, menu        ;print menu
    call print    
                  
    mov dh, row        ;set row to 14 
    call cursor
                                        
    mov bx, 00F0h      ;point to first option   
    call color  
    
                            
L3:              
    mov dh, 0Eh
    call cursor  
    
    lea dx, menu1
    call print 
               
    mov dh, 0Fh              
    call cursor
    
    lea dx, menu2
    call print         

            
    mov ah, 0
    int 16h   
    
    mov arrow, ah
    mov enter, al
           
    mov dh, row
    call cursor
                 
    mov al, arrow
                            
    cmp al, 48h         ;arrow key selection
    je UP          
    cmp al, 50h
    je DOWN      
    
    mov al, enter  
    cmp al, 0Dh         ;enter key 0dh
    je EN         
  
B1:                                                               
    loop L3  
      
    
UP:           
    mov bx, 000Fh      ;set color back to normal
    call color
    
    dec row        ;E - 1 = D
    
    mov bl, 0Dh    ;D
    cmp row, bl
    je U_RESET    ;D => F

U_BACK:    
    mov dh, row
    call cursor     
    
    mov bx, 00F0h         
    call color
    
    jmp B1      
              
U_RESET:    
    add row, 2         ;go back to bottom
    jmp U_BACK     
      
      
      
DOWN:                        
    mov bx, 000Fh   ;set color back to normal
    call color
            
    inc row        
    
    mov bl, 10h    ;condition
    cmp row, bl
    je D_RESET  ;reset cursor
         
D_BACK:    
    mov dh, row
    call cursor    
                
    mov bx, 00F0h
    call color                                      

    jmp B1 
          
D_RESET:
    sub row, 2         ;go back to top
    jmp D_BACK                  
      
;--------------------------------------------------------          

EN:
    cmp row, 0Eh
    je LOAN_FUNC
    ;cmp row, 0Fh         ;to be added more menu selection
    jmp EXIT         
           
LOAN_FUNC:          ;you can move this to your function   
    xor dx, dx
    
    mov ax, 0003   
    int 10h

    lea dx, string
    call print
    
_menu endp
                
end main
