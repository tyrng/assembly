.model small
.stack 100
.data                                
    ;LOGIN---------------------------     
    ARRAY LABEL BYTE
    max db 20
    act db ?
    pass db 20 dup("$")   
    
    loginstr db "Enter pass code $"                       
    password db "123"              
    errorstr db "Pass code doesn't match!$"      
    buffer db 20 dup ("$")

    ;MENU ---------------------------
    menu db "Bank Loan Machine$"
    menu1 db "1. Loan$" 
    menu2 db "2. Exit Program$"  
    string db "This is loan$"       
                   
	arrow db ?          ;this stores input of arrow  
	enter db ?          ;this stores input of enter 	                          
	row db 0Eh                                      
	
	;LOAN-------------------------------     
    errStr db "Max Loan Amount is 15000$"   
    maxloan db "15000"              
    minloan db "01000"  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;<---
    loanStr db "Confirm Amount? $"
    contStr db "Continue ?$" 
    yes db "Yes$"
    no db "No$"      
    zero db 5 dup (30h), "$"
    
    cash db 5 dup (20h), "$" 
    YN db ?   
    col db 25h              ;always point to no 
    num db ?
    ;INTEREST-TABLE-----------------------------
    int_Table1 db "Interest Rate & Loan Duration$"
    int_Table2 db "Loan Duration     1-3 years       4-6years        7-10 years$"
    int_Table3 db "Interest Rate     30%             18%             12%$"
    intStr db "Loan Amount Selected: $" ;cash here
    intDur db "Enter Loan Duration: $"
    
    Duration db 2 dup (?)   ;loan duration for 2 bytes      
	                               	                               
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
    mov ah, 6
    xor al, al
    xor cx, cx
    mov dx, 184Fh       ;end coord
    mov bh, 0Ah         ;cyan bg, green text
    int 10h    
    
    ;borders     
          
    ret
                   
print proc  
    mov ah, 9
    int 21h    
    xor dx,dx
        
    ret                   
             
color proc
    mov ax, 0920h       ;color focus      
    mov dl, 28h         ;col : 24d
    int 10h 
    
    ret

cursor proc    
    mov ah, 2           ;next cursor
    mov bh, 0  
    int 10h
    
    ret    
    
ctscr proc
    mov ax, 0200h       ;set cursor to middle     
    mov bh, 0           ;page 0
    mov dx, 0D28h       ;center
    int 10h
 
    ret       
                
clstr proc 
    xor cx, cx
    lea si, pass
    lea di, buffer
    mov cl, max
    rep movsb
    
    ret      
 
clbyte proc
L7:     
    mov cash[si], 30h         ;clear input
    inc si
        
    loop L7  
    
    ret      
                    
_login proc     
L1:    
    call clstr
    call cls   
    
    mov dx, 0D28h   
    call cursor                      
                 
    xor dx, dx                         
    lea dx, loginstr
    call print 
                 
    mov dx, 0E28h
    call cursor
    
    mov bx, 00A0h     
    mov cx, 0017
    call color  
    
    mov dx, 0E28h
    call cursor
                 
    mov ah, 0Ah        
    lea dx, ARRAY
    int 21h      
             
    xor cx, cx
    mov cx, 3       ;change this as well when you change password 
    mov si, 0          
L2:
    mov bl, password[si]
    cmp pass[si], bl
    jne L1  
    
    inc si
    
    loop L2    
    
    ret     
            
_menu proc   
MENU_SCR:          
    call cls
    call ctscr          
                                
    lea dx, menu        ;print menu
    call print    
                  
    mov dh, row        ;set row to 14      
    mov dl, 28h         ;col : 24d
    call cursor
                                        
    mov bx, 00A0h      ;point to first option  
    mov cx, 0017 
    call color  
    
                            
L3:              
    mov dx, 0E28h
    call cursor  
    
    lea dx, menu1
    call print 
               
    mov dx, 0F28h              
    call cursor
    
    lea dx, menu2
    call print         
    ;add menu3 
            
    mov ah, 0
    int 16h   
    
    mov arrow, ah
    mov enter, al
           
    mov dh, row     
    mov dl, 28h         ;col : 24d
    call cursor
                 
    mov al, arrow
                            
    cmp al, 48h         ;arrow key selection
    je UP          
    cmp al, 50h
    je DOWN      
    
    mov al, enter  
    cmp al, 0Dh         ;enter key 0dh
    je EN1         
  
B1:                                                               
    loop L3  
      
    
UP:           
    mov bx, 000Ah      ;set color back to normal 
    mov cx, 0017
    call color
    
    dec row        
    
    mov bl, 0Dh    
    cmp row, bl
    je U_RESET    

U_BACK:    
    mov dh, row     
    mov dl, 28h     
    call cursor     
    
    mov bx, 00A0h            
    mov cx, 0017
    call color
    
    jmp B1      
              
U_RESET:    
    add row, 2          ;go back to bottom
    jmp U_BACK          
      
DOWN:                        
    mov bx, 000Ah       ;set color back to normal  
    mov cx, 0017
    call color
            
    inc row        
    
    mov bl, 10h         ;condition
    cmp row, bl
    je D_RESET          ;reset cursor
         
D_BACK:    
    mov dh, row    
    mov dl, 28h         
    call cursor    
                
    mov bx, 00A0h            
    mov cx, 0017
    call color                                      

    jmp B1 
          
D_RESET:
    sub row, 2         ;go back to top
    jmp D_BACK                         
    
    
    
                                                                   
LOAN:                   ;you can move this to your function   
    call Loan_Amount
    jmp MENU_SCR   
   
EN1:
    cmp row, 0Eh
    je LOAN
    ;cmp row, 0Fh         to be added more menu selection
    ret            
_menu endp      

            
            
            
            
            
            
            
            
Loan_Amount proc
L_restart:     
    call cls
    call ctscr             
    
    lea dx, zero
    call print
    
    mov cx, 5
    mov si, 0        
    mov num, 2Ch
L4:               
    mov dx, 0D2Ch
    call cursor  
    
	
    mov ah, 0
    int 16h     
                
    cmp al, 0Dh           ;end input
    je L_enter    
    cmp al, 30h
    jb L_err
    cmp al, 39h
    ja L_err    
                           
    mov cash[si], al  
    
    mov dh, 0Dh
    mov dl, num
	call cursor   	
	dec num	
	lea dx, cash         ;not more than 15000
	call print    	
	cmp cx, 1
    je LIMIT     
R1:	
	inc si   	
	loop L4 	  
	jmp L_enter 

L_back1:               ;resume loop
    mov cx, 1 
    jmp R1	

LIMIT:   
    mov cx, 5   
    mov si, 0
L6:        
    mov al, cash[si]
    cmp al, maxloan[si]         ;compare 15000
    jbe L_enter                     ;reset
    loop L6
        
L_err:            
    call Loan_error   
    jmp L_back2    	      ; get yes and no    
;------------------------------------------------  	
L_enter:          
    mov dx, 1122h          ;11:12
    call cursor
  
    lea dx, loanstr       ;confirm amount
    call print
                  
    mov ah, 1
    int 21h
 
    cmp al, "y"
    call Loan_Duration    ;je ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
L_right:          
    mov dx, 141Fh          ;print yes coord - 1
    call cursor
    mov col, 25h 

    mov bx, 000Ah
    mov cx, 0005
    call color  
    
L_back2:                  ;start coordinate first option
    mov dx,1425h
    call cursor
    
    mov bx, 00A0h      ;adjust coord
    mov cx, 0004
    call color
    
    jmp L_condition
L_farjmp:
    jmp L_restart                      
    
L_left:       
    mov dx, 1425h
    call cursor

    mov bx, 000Ah      ;point to first option
    mov cx, 0004   
    call color
    
    mov col, 20h
    
    mov dx, 141Fh
    call cursor
    
    mov bx, 00A0h  
    mov cx, 0005
    call color             ;change cx to 4 add own function

L_condition:          
    call Loan_condition
    
    mov ah, 0
    int 16h    
    
    mov YN, ah           ; yes and no
    mov enter, al       ;reuse enter variable
    
    cmp YN, 4Bh         ;YES
    je L_left  
    
    cmp YN, 4Dh         ;NO
    je L_right    
    
    cmp enter, 0Dh 
    je L_end

    loop L_condition          ;loop left and right  
    
L_end:             ;return    
    cmp col, 20h
    je L_farjmp    
    
    mov cx, 5
    xor si, si
    call clbyte
                                                    
    ret
Loan_Amount endp               

Loan_error proc
    mov dx, 1021h               ;error display
    call cursor
 
    lea dx, errStr              
    call print       
              
    mov cx, 5 
    lea bx, cash 
    call clbyte          ;clear byte
    
    mov dx, 1122h        ;print below 
    call cursor
    
    lea dx, contStr       ;continue?
    call print            
    
    ret

Loan_condition proc
    mov dx, 1420h         ;20h
    call cursor         
    
    lea dx, yes
    call print 
    
    mov dx, 1426h
    call cursor
    
    lea dx, no
    call print                  ;cursor for no
    
    ret


Loan_Duration proc 
    call cls
    call ctscr    
    
    lea dx, int_Table1
    call print        
               
    mov dx, 0E23h                     
    call cursor
    
    lea dx, int_Table2
    call print    
    
    mov dx, 0F23h                     
    call cursor
    
    lea dx, int_Table3
    call print    
    
    mov dx, 1025h                     
    call cursor
    
    lea dx, intStr
    call print          
    
    lea dx, cash    
    call print    
    
    mov dx, 1125h                     
    call cursor
    
    lea dx, intDur
    call print
               
    mov ah, 0
    int 16h              
               
    ret
Loan_Duration endp           
           
end main
