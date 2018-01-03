.model small
.stack 100
.data                                
    ;LOGIN---------------------------     
    ARRAY LABEL BYTE
    max db 15
    act db ?
    pass db 15 dup("$")   
    
    loginstr db "Enter pass code $"                       
    password db "123"              
    errorstr db "Pass code doesn't match!$"      
    buffer db 15 dup ("$")

    ;MENU ---------------------------
    menu db "Bank Loan Machine$"
    menu1 db "1. Loan$" 
    menu2 db "2. Exit Program$"  
    string db "This is loan$"       
                   
	arrow db ?          ;this stores input of arrow  
	enter db ?          ;this stores input of enter 	                          
	row db 0Eh                                      
	
	;LOAN-------------------------------   
	LoanTitle db "Enter loan amount (RM 1,000 - RM 15,000) $"  
    errStr db "Max Loan Amount is 15,000$"   
    maxloan db "15000"              
    minloan db "01000"  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;1;;;;;;;;;;;;;;;;;;;;;;;;;;;;<---
    decStr db "Confirm Amount? $"  
    contStr db "Continue ?$"       
    redoStr db "Retry enter Year? $"
    yes db "Yes$"
    no db "No$"      
    zero db 5 dup (30h), "$"
    
    cash db 5 dup (20h), "$" 
    YN db ?   
    col db 25h              ;always point to no 
    num db ?                                          
    bool db ?
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
    mov dl, 20h         ;col : 24d
    int 10h 
    
    ret

cursor proc    
    mov ah, 2           ;next cursor
    mov bh, 0  
    int 10h
    
    ret    
    
ctscr proc
    mov ax, 0200h       ;set cursor to middle      title set
    mov bh, 0           ;page 0
    mov dx, 0C1Eh       ;center
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
    mov cash[si], 20h         ;clear input
    inc si
        
    loop L7  
    
    ret      
                    
_login proc     
L1:    
    call clstr
    call cls 
    call ctscr  
                        
                 
    xor dx, dx                         
    lea dx, loginstr
    call print 
                 
    mov dx, 0E1Dh
    call cursor
    
    mov bx, 00A0h     
    mov cx, 0017
    call color  
    
    mov dx, 0E1Eh
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
    
    lea dx, menu
    call print
                  
    mov dh, row        ;set row to 14      
    mov dl, 1Eh         ;col : 24d
    call cursor
                                        
    mov bx, 00A0h      ;point to first option  
    mov cx, 0017 
    call color  

                            
L3:              
    mov dx, 0E1Eh
    call cursor  
    
    lea dx, menu1
    call print 
               
    mov dx, 0F1Eh              
    call cursor
    
    lea dx, menu2
    call print         
    ;add menu3 
            
    mov ah, 0
    int 16h   
    
    mov arrow, ah
    mov enter, al
           
    mov dh, row     
    mov dl, 1Eh         ;col : 24d
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
    mov dl, 1Eh     
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
    mov dl, 1Eh         
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
L_restart:          ;press no to go her   
    mov cx, 5       ;clear byte of cash if no
    xor si, si
    call clbyte
    
    call cls
    call ctscr           
                     
    mov dx, 0C1Ah       ;about top center       ;if jump range issue send this to new function
    call cursor      
                                
    lea dx, LoanTitle     
    call print                    
    
    mov dx, 0E24h       ;24 as center   #fixed
    call cursor
    
    lea dx, zero    ;00000
    call print
                                         
;money-------------------------------------------------------                                         
    call Loan_Input   
     
    cmp bool, 0
    je L_enter
                 
    jmp L_choice                      

LoanDuration:                     ;redo if wrong input    
    call Loan_Duration      
                                       
    call Confirmation
    call Loan_Confirmation  ;YES / NO     
    
    cmp col, 1Eh            ;YES = go to jon's calculation 
    ;je JON'S CALCULATION                                           <---- take cash variable to tyrone conversion
    mov dx, 1122h       ;fixed 22
    call cursor                                
    
    mov bx, 04h           ;Change this color when you change background     
    mov cx, 20
    call color  
                                
    lea dx, redoStr
    call print
                       
    call Loan_Confirmation
    
    cmp col, 1Eh            ;RETRY? YES = go back loanduration              
    je LoanDuration
    
    jmp L_choice

L_enter:                    ;successfully entered loan amount
    call Confirmation    
    call Loan_Confirmation   
       
    cmp col, 1Eh            ;YES
    je LoanDuration                                                                      

L_choice:    
    call Continue           ;Continue?   
    call Loan_Confirmation  ;YES / NO     
    
    cmp col, 1Eh            ;1Eh = YES                   
    je L_restart
                                                
    ret
Loan_Amount endp    





Loan_Input proc
    mov cx, 5
    mov si, 0        
    mov num, 28h    ;print moves forward
L4:               
    mov dx, 0E28h   ;fixed col : 26h 
    call cursor  
	
    mov ah, 1
    int 21h     
                
    cmp al, 0Dh           ;end input
    je L_enter    
    cmp al, 30h
    jb L_error
    cmp al, 39h
    ja L_error    
                           
    mov cash[si], al  
    
    mov dh, 0Eh
    mov dl, num
	call cursor  
	 	
	dec num	         ;left each time
	
	lea dx, cash         ;not more than 15000
	call print
	    	
	cmp cl, 1
    je LIMIT                                      
R1:	
	inc si   	
	loop L4 	
	            
	mov bool, 0                       
skip1:
	  
	ret 
      
;Constraints----------------          
        
LIMIT:   
    cmp cash[0], 1
    jbe R2    
    cmp cash[1], 5
    jbe R2

    mov cx, 3                                                     ;<------------------fix this
    mov si, 2
L6:        
    mov al, cash[si]
    cmp al, maxloan[si]         ;compare 15000
    ja L_error                     ;reset     
    
    inc si
    loop L6                                         
    
R2:                                    ;resume loop 
    mov cx, 1 
    jmp R1	      
    
L_error:            
    call Loan_error         ;Get error msg and clear content    
    mov bool, 1
    jmp skip1
    
Loan_Input endp    



Loan_Confirmation proc     ;THIS FUNCTION FOR YES AND NO
    
    jmp L_GOTO                                      
    
;---------------------------------------------------    
    
L_right:                  ;NO DECISION
    mov dx, 141Fh          ;print yes coord - 1
    call cursor 

    mov bx, 000Ah
    mov cx, 5
    call color  
    
L_GOTO:                  ;start coordinate first option
    mov dx,1425h
    call cursor    
       
    mov col, 25h       ;25 indicates NO (right)
    
    mov bx, 00A0h      ;adjust coord
    mov cx, 4
    call color
    
    jmp L_condition                                
    
L_left:                 ;YES DECISION 
    mov dx, 1425h
    call cursor

    mov bx, 000Ah      ;point to first option
    mov cx, 4   
    call color
    
    mov dx, 141Fh
    call cursor 
    
    mov col, 1Eh        ;1E indicates YES (left)
    
    mov bx, 00A0h  
    mov cx, 5
    call color             

L_condition:                    ;HERE IS FUNCTION
    call Loan_condition         ;PRINT YES AND NO
    
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

    loop L_condition            ;loop left and right  
    
L_end:                  ;return brings the content of column    left and right  
    
    ret
Loan_Confirmation endp                   
    
Confirmation proc           ;print Confirm     
    mov dx, 1122h
    call cursor                                
    
    mov bx, 04h           ;Change this color when you change background     
    mov cx, 20
    call color  
    
    lea dx, decStr          ;Confirm Input?
    call print     
    
    ret
    

Continue proc                   ;print continue 
    mov dx, 1122h               ;print below 
    call cursor
    
    mov bx, 04h           ;Change this color when you change background     
    mov cx, 20
    call color 
    
    lea dx, contStr             ;continue?
    call print  
                           
    ret                       
                           

Loan_error proc
    mov dx, 101Eh               ;error display
    call cursor
 
    lea dx, errStr              
    call print       
              
    mov cx, 5           
    xor si, si
    lea bx, cash         
    call clbyte                 ;clear byte          
    
    ret

Loan_condition proc             ;THIS PRINTS YES AND NO
    mov dx, 1420h               ;14h 20h 
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
    
    mov dx, 0909h
    call cursor
    
    lea dx, int_Table1
    call print        
               
    mov dx, 0A09h                     ;9h col 
    call cursor                         
    
    lea dx, int_Table2
    call print    
    
    mov dx, 0B09h                     
    call cursor
    
    lea dx, int_Table3
    call print    
    
    mov dx, 0C09h                     
    call cursor
    
    lea dx, intStr
    call print          
    
    lea dx, cash    
    call print    
    
    mov dx, 0D09h                     
    call cursor
    
    lea dx, intDur
    call print
               
    mov ah, 1
    int 21h              
               
    ret
Loan_Duration endp           
           
end main
