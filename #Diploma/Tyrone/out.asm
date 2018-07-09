.model small
.stack 100
.data                                
    ;LOGIN---------------------------     
    ARRAY LABEL BYTE
    max db 15
    act db ?
    pass db 15 dup("$")   
    
    loginstr db "Enter pass code $"                       
    password db "eeyore"              
    errorstr db "* Pass code doesn't match!$"      
    buffer db 15 dup ("$")

    ;MENU ---------------------------
    menu db "Bank Loan Machine$"
    menu1 db "1. Loan$"     
    menu2 db "2. Receipt$"
    menu3 db "3. Exit Program$"  
       
	arrow db ?          ;this stores input of arrow  
	enter db ?          ;this stores input of enter 	                          
	row db 0Eh                                      
	
	;LOAN-------------------------------   
	LoanTitle db "Enter loan amount (1,000 USD - 15,000 USD) $"  
    errStr db "Invalid! Check your Input$"   
    maxloan db "15000"              
    minloan db "01000"                      ;<---min loan do this
    decStr db "Confirm Amount? $"  
    contStr db "Continue Progress?$"       
    redoStr db "Retry enter Year? $"                        
    yes db "Yes$"
    no db "No$"      
    zero db 5 dup (30h), "$"
    
    tempStr db 5 dup (20h), "$" 
    YN db ?   
    col db 25h                      ;always point to no 
    num db ?                        ;row print                   
    bool db ?                       ;no choice           
    inputVar dw ? 
    exp dw 1, 10, 100, 1000, 10000        
    
    ;INTEREST-TABLE-----------------------------
    int_Table1 db "Interest Rate & Loan Duration$"
    int_Table2 db "Loan Duration     1-3 years       4-6 years        7-10 years$"
    int_Table3 db "Interest Rate     30%             18%             12%$"
    intStr db "Loan Amount Selected: (USD) $" ;cash here
    intDur db "Enter Loan Duration : $"  
    yearError db "Please enter year between 0 - 10$"
                                                               
    Year Label Byte
    max2 db 3
    act2 db ?
    Duration db 3 dup (?)                            
    bytes db 10, 1
    
    ;FORMULA-------------------------------------
    formula1 db "Total Compounded Loan = P x (1 + R / N)^(N x T)$" 
    formula2 db "Monthly Loan Payment  = (P x R / N) / (1 - (1 + R / N)^(-N x T)$"
    equalStr db "= (USD)   $"       
    
    ;RECEIPT--------------------------------------
    recStr db "Loan History$"  
    History db "history.txt"
    ;FNAME db "REC1.txt"
    handle dw ?
    
;-------------------------------------------------------------------------------------------
tens DW 10000,1000,100,10,1
;inputVar DW ?	;Loan Amount (Decimal Form)
outputVar DW ?
StringOutput DB 30H,30H,30H,30H,30H
;------------------------------------

;---CONSTANT INTEREST RATES ARRAY---
interestRates DW 1010, 1015, 1025	;12%, 18%, 30%


;---Number of years the loan is borrowed for
tVar DB 2

;---Number of times the interest is compounded annually
nVar DB 12
                                                        
;---(N x T) variable
ntVar DB ?

;---(1 + R/N) CONSTANT variable----
constantVar DW 1025
cString DW ?,?,?,?

;---Floating point variables
fPoint DW ?
fpString DW ?,?,?,?

;---Total compounded loan variables
totalLoan DW 0
decimalPoint DW 0
dpString DB 30H, 30H
tempDP DW ?


;---Power steps for floating point 
powSteps DW 4 dup (?)
powDivisor DW 100, 10, 1

;---Dramatic text effect 
looper DB 2


;========MONTHLY LOAN PAYMENT VARIABLES==========
loanXinterest DW ?
loanDP DW ?

d_loopVar DW ?
denomVar DW ?
	
mLoanPayment DW ?
mLoanPayment_DP DW ?
;---------------------------------------------------------------      

;-------------------------------------------LOGO----------------------------------------  

    logo01  db "                                   *@.@@ @@ @*@"
            db 10,13,"                               @@@             @@@("
            db "$"

    logo02  db 10,13,"                          @@@                       @/("
            db 10,13,"                         @      @@ %&                  @."
            db "$"

    logo03  db 10,13,"                       @       @     @                   @,"
            db 10,13,"                    @@         #      @   @@              *@."
            db "$"

    logo04  db 10,13,"                    @          @       @ @  @               @@ "
            db 10,13,"                   @           ,             :               @@"
            db "$"

    logo05  db 10,13,"                 &@           &              @                @*"
            db 10,13,"                 @           %                @               &,"
            db "$"

    logo06  db 10,13,"                @@          %                  @               @."
            db 10,13,"                 @          *.                  @              @@"
            db "$"

    logo07  db 10,13,"                 (          ,                   (              @/"
            db 10,13,"                 @         ,                     ,             @@"
            db "$"

    logo08  db 10,13,"                @@         @                      (            @"
            db 10,13,"                 @          <                      (          @"
            db "$"

    logo09  db 10,13,"                 @@          &                      @         @"
            db 10,13,"                  ,@         /                      @        @@"
            db "$"

    logo10  db 10,13,"                   *@       /                        \      @@"
            db 10,13,"                    %@     /                          #   @@"
            db "$"

    logo11  db 10,13,"                       @ .      WOLFE'S LOAN CORP.     # @@"
            db 10,13,"                         @                            @@@"
            db "$"

    logo12  db 10,13,"                          . @(                     @@"
            db 10,13,"                           Press any key to continue..."
            db "$"

;---------------------------------------------------------------------------------------

	                               	                               
.code
main proc
	mov ax, @data
	mov ds, ax    
    
    call _logo                 
    call _login                     
    call _menu     
 
EXIT:                
    mov ah, 4ch
    int 21h                     
main endp  

cls proc
    mov ax, 0600h
    xor cx, cx
    mov dx, 184Fh       ;end coord
    mov bh, 0Ah         ;cyan bg, green text
    int 10h    

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
    mov tempStr[si], 20h         ;clear input
    inc si       
    loop L7  
    
    ret      
                    
_login proc     
    call cls 
L1:                                    ;,------------------ add err msg and ****
    call ctscr  
                                     
    xor dx, dx                         
    lea dx, loginstr
    call print 
                 
    mov dx, 0E1Dh
    call cursor
    
    mov bx, 00AAh   ;A0h     
    mov cx, 0017
    call color  
    
    mov dx, 0E1Eh
    call cursor
                 
    mov ah, 0Ah        
    lea dx, ARRAY
    int 21h      
             
    xor cx, cx
    mov cx, 6       ;change this as well when you change password 
    mov si, 0          
L2:
    mov bl, password[si]
    cmp pass[si], bl
    jne invalid  
    
    inc si       
    loop L2      
     
    ret   
    
invalid:    
    mov dx, 1019h
    call cursor
    
    mov bx, 000Ch     
    mov cx, 0026
    call color  
    
    lea dx, errorstr
    call print  
    
    call clstr       
                  
    jmp L1
_login endp    
            
_menu proc     
    
menu_scr:          
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
    
    mov dx, 101Eh
    call cursor        
    
    lea dx, menu3
    call print
            
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
    mov cx, 0018
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
    add row, 3          ;go back to bottom
    jmp U_BACK          
      
DOWN:                        
    mov bx, 000Ah       ;set color back to normal  
    mov cx, 0017
    call color
            
    inc row        
    
    mov bl, 11h         ;condition
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
    sub row, 3         ;go back to top
    jmp D_BACK                             
                                                                   
Loan_Function:                   ;you can move this to your function   
    call Loan_Amount
    jmp menu_scr   
    
Receipt_Function:
    call Receipt
    jmp menu_scr    
   
EN1:
    cmp row, 0Eh
    je Loan_Function
    cmp row, 0Fh         ;to be added more menu selection
    je Receipt_Function 
    
    call cls
    ret            
_menu endp      

Receipt proc
    call cls
    
    lea dx, recStr 
    call print

;	mov ah, 3Dh 	;open existing file
;	mov al, 1   	;0 - read, 1 - write, 2 - read&write 
;	lea dx, history	; ASCIIZ filename to open
;	int 21h
;
;	mov handle, ax	;handle or err code3
;
;	mov ah, 42h
;	mov bx, handle	;move file ptr
;	xor cx, cx
;	xor dx, dx
;	mov al, 02h
;	int 21h
;
;	mov ah, 40h	    ; write file
;	mov bx, handle	; file handle for screen
;	mov cl, 5	; len of message (bytes)
;	lea dx, MSG	; copy address to DX
;	int 21h		; display MSG executed 	
;
;	;append function
;	mov ah, 40h	; write file
;	mov bx, handle	; file handle for screen
;	mov cl, 2	; len of message (bytes)
;	lea dx, nl	; copy address to DX
;	int 21h		; display MSG executed
;                  
    ret        
Receipt endp
            
Loan_Amount proc
L_restart:          ;press no to go her   
    mov cx, 5       ;clear byte of cash if no
    xor si, si
    call clbyte
    
    call cls
    call ctscr           
                     
    call Loan_Start                 
;money-------------------------------------------------------                                         
    call Loan_Input   
     
    cmp bool, 0
    je L_enter
                 
    jmp L_choice                 
    
LoanComputation:  
    call FormulaPrt
    
    jmp L_choice

LoanDuration:                     ;redo if wrong input    
    call Loan_Duration      
                                       
    call Confirmation
    call Loan_Confirmation  ;YES / NO     
    
    cmp col, 20h            ;YES = go to jon's calculation  
    je LoanComputation
    
    mov dx, 111Fh       ;1F
    call cursor                                
    
    mov bx, 0Ch           ;Change this color when you change background     
    mov cx, 20
    call color  
                                
    lea dx, redoStr
    call print
                       
    call Loan_Confirmation
    
    cmp col, 20h            ;RETRY? YES = go back loanduration              
    je LoanDuration
    
    jmp L_choice

L_enter:                    ;successfully entered loan amount
    call Confirmation    
    call Loan_Confirmation   
       
    cmp col, 20h            ;YES
    je LoanDuration                                                                      

L_choice:    
    call Continue           ;Continue?   
    call Loan_Confirmation  ;YES / NO     
    
    cmp col, 20h            ;1Eh = YES                   
    je L_restart
                                                
    ret
Loan_Amount endp    


Loan_Input proc   
    xor ax, ax
    mov inputVar, ax  
    
    mov cx, 5
    mov si, 0                         
    mov num, 28h    ;print moves forward
L4:               
    mov dx, 0A28h   ;fixed col : 26h 
    call cursor  

    mov ah, 1
    int 21h     
                
    cmp al, 0Dh           ;end input
    je LIMIT   
    cmp al, 30h
    jb L_error
    cmp al, 39h
    ja L_error    
                           
    mov tempStr[si], al  
    
    mov dh, 0Ah
    mov dl, num
	call cursor  
	 	
	dec num	         ;left each time
	
	lea dx, tempStr         ;00001 00021 00321
	call print
	                                                         	
	inc si   	
	loop L4 	  
	
	jmp LIMIT        
R1:	            
	mov bool, 0         ;correct                      
skip1:
	  
	ret                               
        
LIMIT:                
    mov cx, 5 
    mov si, 5
    mov di, 0    
    
DecHex:       
    xor ax, ax 
    mov al, tempStr[si-1]
    cmp al, 20h
    je ignore
    
    sub al, 30h
    mul exp[di]                     ;16^0
    
    add inputVar, ax      
    add di, 2 
ignore:
    dec si                
               
    loop DecHex   
                  
    mov bx, inputVar              
    cmp bx, 3A98h           ;max loan 15000
    ja L_error          
    cmp bx, 03E8h           ;min loan 1000
    jb L_error                  
    
    jmp R1                           ;R = resume	      
    
L_error:            
    call Loan_error         ;Get error msg and clear content    
    mov bool, 1
    jmp skip1
    
Loan_Input endp    



Loan_Confirmation proc     
    
    jmp L_GOTO                                      
    
;---------------------------------------------------    
    
L_right:                  ;NO 
    mov dx, 141Fh          ;cursor - 1
    call cursor 

    mov bx, 000Ah
    mov cx, 5
    call color  
    
L_GOTO:                  ;start coordinate first option
    mov dx,142Ah
    call cursor    
       
    mov col, 2Bh       ;25 indicates NO (right)
    
    mov bx, 00A0h      ;adjust coord
    mov cx, 4
    call color
    
    jmp L_condition                                
    
L_left:                 ;YES DECISION 
    mov dx, 142Ah
    call cursor

    mov bx, 000Ah      ;point to first option
    mov cx, 4   
    call color
    
    mov dx, 141Fh
    call cursor 
    
    mov col, 20h        ;1E indicates YES (left)
    
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


Loan_Start proc
    mov dx, 0916h       ;about top center       ;if jump range issue send this to new function
    call cursor      
                                
    lea dx, LoanTitle     
    call print                    
    
    mov dx, 0A24h       ;24 as center   #fixed
    call cursor
    
    lea dx, zero    ;00000
    call print
                        
    ret                       
    
Confirmation proc           ;print Confirm     
    mov dx, 1120h
    call cursor                                
    
    mov bx, 0Ch           ;Change this color when you change background     
    mov cx, 20
    call color  
    
    lea dx, decStr          ;Confirm Input?
    call print     
    
    ret
    

Continue proc                   ;print continue 
    mov dx, 111Eh               ;print below 
    call cursor
    
    mov bx, 0Ch           ;Change this color when you change background     
    mov cx, 20
    call color 
    
    lea dx, contStr             ;continue?
    call print  
                           
    ret                       
                           

Loan_error proc
    mov dx, 0E1Bh               ;error display
    call cursor
 
    lea dx, errStr              
    call print       
              
    mov cx, 5           
    xor si, si
    lea bx, tempStr         
    call clbyte                 ;clear byte          
    
    ret

Loan_condition proc             ;THIS PRINTS YES AND NO
    mov dx, 1420h               ;14h 20h 
    call cursor         
    
    lea dx, yes
    call print 
    
    mov dx, 142Bh
    call cursor
    
    lea dx, no
    call print                  ;cursor for no
    
    ret


Loan_Duration proc 
    call cls     
    
    mov dx, 031Bh       ;cursor
    call cursor
    
    lea dx, int_Table1              
    call print 
    
    mov dx, 060Bh       ;cursor
    call cursor
    
    lea dx, int_Table2
    call print 
 
    mov dx, 070Bh       ;cursor      
    call cursor
    
    lea dx, int_Table3
    call print  
    
    mov dx, 0912h       ;cursor
    call cursor
    
    lea dx, intStr
    call print     
    
    mov bx, 000Eh           ;Yellow     
    mov cx, 0010
    call color  

    lea dx, tempStr
    call print     
    
    mov dx, 0B12h                     
    call cursor
    
    lea dx, intDur
    call print     
    
    mov bx, 000Eh           ;Yello     
    mov cx, 0005
    call color  
               
    mov ah, 0Ah
    lea dx, Year
    int 21h      
    
    xor ax, ax
    xor bx, bx              
                                 
    mov cl, act2
    mov si, cx
digits:
    mov al, Duration[si-1]       
    sub al, 30h 
    
    mul bytes[si-1]
    add bl, al

    dec si
    loop digits    
  
    cmp bl, 1
    jb LimitOver
    cmp bl, 0Ah
    ja LimitOver         
                              
    mov tVar, bl              ;; jump to err <-----------------------------------------------------------------------------------eqjfewweuf 
                
    xor bx, bx 
        cmp tVar,3
        jbe rate1
        cmp tVar,6
        jbe rate2          
        
        mov bx, interestRates[0]    ;1010
        jmp Here
        rate1:
        mov bx, interestRates[4]    ;1025
        jmp Here
        rate2: 
        mov bx, interestRates[2]    ;1015    
Here:                               
        mov constantVar, bx 
                 
L_Duration:               
    ret                             ;return here
                                   
LimitOver:    
    mov dx, 1121h         
    call cursor                                
    
    mov bx, 0Ch           ; light red     
    mov cx, 20
    call color  
    
    lea dx, yearError
    call Continue
    jmp L_Duration    

Loan_Duration endp  

FormulaPrt proc    
    mov ax, 0600h       ;clear screen
    xor cx, 1100h       ;start coord
    mov dx, 184Fh       ;end coord
    mov bh, 0Ch         ;back bg, green text
    int 10h    
    
    ;Total           
    mov dx, 0F0Bh       ;cursor
    call cursor
    
    lea dx, formula1                
    call print
    
    ;WORKING
    call _CONST_SETTING
    call _FINALOAN 
    
    mov dx, 1021h       ;cursor
    call cursor             
    
    lea dx, equalStr
    call print
                      
    call _VARSTRING
                    
    ;Monthly Payment  
    mov dx, 120Bh       ;cursor
    call cursor
    
    lea dx, formula2
    call print        
 
    ;WORKING   
    call _MONTHLY_LOAN  
    
    mov dx, 1321h       ;cursor
    call cursor 
    
    lea dx, equalStr
    call print  
    
    call _VARSTRING
           
    mov ah, 0                           
    int 16h      
    
    mov ah, 6
    mov al, 0Ch
    mov bh, 0Ah
    xor cx, cx
    mov dx, 184Fh   ;24 : 79
    int 10h   
               
                             
    ret
               
FormulaPrt endp    

;==================

;==================

;==============================================================
_CONST_SETTING PROC	

 ;----CONVERT CONSTANT RATE SELECTED INTO ARRAY
 
 MOV SI, 6
 MOV AX, constantVar
 ;---Splitting SELECTED interest rate into array (cString)
 CONST_SEPERATOR:
 XOR DX, DX
 
 DIV powDivisor[2]
 MOV cString[SI], DX
 
 CMP SI, 0
 JE RETURN_CS
 JA DECREMENT_CS
 
 DECREMENT_CS:
 SUB SI, 2
 JMP CONST_SEPERATOR
 
 RETURN_CS:

 RET
_CONST_SETTING ENDP


_POWLOOP PROC   
 ;====================WELCOME TO THE POWER LOOP FUNCTION==============
 
 ;---LOOP SETTINGS---
 XOR AX, AX
 MOV AL, nVar
 MUL tVar
  
 ;---Initializing loop---
 MOV CX, AX
 SUB CX, 1
 MOV AX, constantVar
 MOV fPoint, AX  
 
 BIGLOOP:

 XOR BX, BX
 XOR DX, DX
 
 MOV SI, 0
 MOV DI, 6

 ;---POWER^2 FORMULA
 POWER:
 
 MOV AX, fPoint
 MUL cString[DI]
 DIV powDivisor[SI]
 
 MOV powSteps[SI], AX
 ADD SI, 2
 SUB DI, 2

 
 CMP SI, 6
 JE P2 
 JB POWER
 
 P2:
 MOV AX, fPoint
 MUL cString[DI]
 MUL powDivisor[2]
 MOV powSteps[SI], AX

 JMP FLOATP 
 
 ;---Floating point calculations---
 FLOATP:
 MOV SI, 0
 MOV DI, 0
 
 ;---Add floating point steps to get final floating point
 MOV AX, powSteps[SI]
 ADD AX, powSteps[SI+2]
 ADD AX, powSteps[SI+4]
 ADD AX, powSteps[SI+6]
 MOV fPoint, AX
 
 ;---Round off 4th decimal place
 MOV AX, fPoint
 DIV tens[6]
 MOV fPoint, AX 
 
 CMP DL, 5
 JAE roundPlus
 JB  roundNone
 
 roundPlus:
 MOV AX, fPoint
 INC AX
 MOV fPoint, AX
 JMP roundNone
 
 
 roundNone:
 LOOP BIGLOOP
 
 
 XOR AX, AX
 XOR BX, BX
 XOR SI, SI
 XOR DX, DX
 
 MOV SI, 6
 MOV AX, fPoint
 ;---Splitting compounded interest rate into array (fpString)
 FP_SEPERATOR:
 XOR DX, DX
 
 DIV powDivisor[2]
 MOV fpString[SI], DX
 
 CMP SI, 0
 JE RETURN2
 JA DECREMENT
 
 DECREMENT:
 SUB SI, 2
 JMP FP_SEPERATOR
 
 RETURN2:
 MOV AX, fPoint
 XOR AX, AX
 MOV fPoint, AX
 
 RET
 _POWLOOP ENDP
 
 
 _FINALOAN PROC
 
 ;==========CALCULATION PART II===========
 ;(Multiplying loan with compounded rate)
 SETUP_BM:
 
 CALL _POWLOOP
 
 XOR AX, AX
 XOR BX, BX
 MOV SI, 6
 MOV DI, 2
 ;---Compounded loan amount CALCULATION---
 BIG_MULTIPLY:
 XOR DX, DX
 
 MOV BX, totalLoan
 MOV AX, inputVar
 DIV tens[DI]
 
 MOV tempDP, DX
 MUL fpString[SI]
 
 ADD AX, BX
 MOV totalLoan, AX
 
 
 CMP SI, 0
 JE DP_ROUNDING
 JA DECIMAL_CALC
 
 ;----CALCULATION FOR DECIMALS----
 DECIMAL_CALC:
 XOR BX, BX
 
 MOV BX, decimalPoint
 MOV AX, tempDP
 MUL tens[SI+2]
 
 MUL fpString[SI]
 ADD BX, AX
 
 MOV decimalPoint, BX
 
 ADD DI, 2
 SUB SI, 2
 JMP BIG_MULTIPLY
 
 
 ;---ROUNDING OFF TO 2DECIMAL POINTS---
 DP_ROUNDING:
 XOR AX, AX
 XOR BX, BX
 MOV SI, 2
  
 MOV AX, decimalPoint
 DIV tens[SI]
 
 MOV decimalPoint, DX
 
 CMP AX, 1
 JAE LOAN_ROUNDUP
 JB LOOP_DP
 
 LOAN_ROUNDUP:
 MOV BX, totalLoan
 ADD BX, AX
 MOV totalLoan, BX
 
 JMP LOOP_DP
 
 
 LOOP_DP:
 XOR DX, DX
 ADD SI, 4
 MOV AX, decimalPoint
 DIV tens[SI]
 
 MOV decimalPoint, AX
  
 CMP DX, 5
 JAE DP_ROUNDUP
 JB RETURN_FL

 
 DP_ROUNDUP:
 MOV AX, decimalPoint
 INC AX
 MOV decimalPoint, AX
 
 JMP RETURN_FL
 
 
 ;---RETURN FINAL COMPOUNDED LOAN VALUES
 RETURN_FL:
 XOR DX, DX
 ;---Split decimal point---
 MOV AX, decimalPoint
 DIV tens[6]
 
 ADD dpString[0], AL
 ADD dpString[1], DL
 
 ;---Move total loan to outputVar---
 MOV AX, totalLoan
 MOV outputVar, AX
 
 ;---Clear decimalPoint var---
 XOR AX, AX
 MOV decimalPoint, AX
 
 ;---Clear totalLoan---
 MOV totalLoan, AX
 
 
 ;-----------------------------
 ;MOV BX,inputVar ; TEMPORARY
 ;MOV outputVar,BX ; TEMPORARY
 
 RET
_FINALOAN ENDP   


_VARSTRING PROC ; CONVERT SINGLE VARIABLE TO OUTPUT STRING
 MOV SI,0
 MOV DI,0
VARSTRING:
 MOV AX,0
 MOV DX,0 
 
 MOV AX,outputVar
 DIV tens[DI]
 MOV outputVar,DX
 ADD stringOutput[SI],AL

 INC SI
 ADD DI,2
 
 CMP SI,4
 JBE VARSTRING
 JA SET_DPRINT
 
 ;---Print out remaining decimals
 SET_DPRINT:
 MOV SI, 0 
 DECIMAL_PRINT:
 
 CMP stringOutput[SI], 30H 
 
 JA D_PRINT
 
 INC SI
 JMP DECIMAL_PRINT
 
 
 D_PRINT:
 
 MOV AH,02H
 MOV DL,stringOutput[SI]
 INT 21H
 
 INC SI
 
 CMP SI, 4
 JBE D_PRINT

 ;-------------------------------
 
 XOR DX, DX
 
 MOV AH, 02H    ;---Print out '.'---
 MOV DL, 2EH
 INT 21H
 
 MOV AH, 02H    ;---Print out decimals---
 MOV DL, dpString[0]
 INT 21H
 
 MOV AH, 02H
 MOV DL, dpString[1]
 INT 21H
 
 JMP CLEAR_PRINT
 
 CLEAR_PRINT:
 MOV SI,0
 MOV DI,0
 
 RESETOUTPUT: 
 MOV StringOutput[SI],30H
 MOV dpString[DI],30H
 INC SI
 INC DI
 CMP SI,5
 JB RESETOUTPUT 
 
 RET        
_VARSTRING ENDP



;===============================
_MONTHLY_LOAN PROC
 
 MOV SI, 6
 MOV DI, 2 
 
 XOR AX, AX
 MOV loanXinterest, AX
 
 MLOAN_MULTIPLY:
 XOR DX, DX
 
 MOV AX, inputVar
 MOV BX, loanXinterest
 DIV tens[DI]
 
 MOV tempDP, DX
 MUL cString[SI]
 
 ADD AX, BX
 MOV loanXinterest, AX
 
 CMP SI, 2
 JE MLOAN_ROUNDING
 JA MDECIMAL_CALC
 
 ;---CALCULATION FOR DECIMALS----
 MDECIMAL_CALC:
 
 MOV BX, decimalPoint
 MOV AX, tempDP
 MUL tens[SI+2]
 
 MUL cString[SI]
 ADD BX, AX
  
 MOV decimalPoint, BX
 
 ADD DI, 2
 SUB SI, 2
 
 JMP MLOAN_MULTIPLY 


 MLOAN_ROUNDING:
 XOR BX, BX
 XOR DX, DX
 MOV SI, 2
 
 MOV AX, decimalPoint
 DIV tens[SI]
 
 MOV decimalPoint, DX
 
 CMP AX, 1
 JAE MLOAN_ROUNDUP
 JB MLOOP_DP
 
 
 MLOAN_ROUNDUP:
 MOV BX, loanXinterest
 ADD BX, AX
 MOV loanXinterest, BX
 
 JMP MLOOP_DP
               
               
 MLOOP_DP:
 XOR DX, DX
 ADD SI, 4  
 MOV AX, decimalPoint
 DIV tens[SI]
 
 MOV decimalPoint, AX
 
 CMP DX, 5
 JAE MDP_ROUNDUP
 JB DENOMINATOR_CALC
 
 
 MDP_ROUNDUP:
       
 MOV AX, decimalPoint
 INC AX
 MOV decimalPoint, AX
 
 JMP DENOMINATOR_CALC
                        
 
 ;===============DENOM==================
 ;====HARDEST PART OF THE FORMULA!!!====                       
 DENOMINATOR_CALC:
 
 ;---MOVE decimal point to loanDP---
 MOV AX, decimalPoint
 MOV loanDP, AX
 
 ;---Clear decimalPoint var---
 XOR AX, AX
 MOV decimalPoint, AX
 
 
 ;=============CALCULATION PART==============
 
 ;===BOTTOM CALCULATION===
 
 CALL _POWLOOP
 
 ;---Round off 3rd decimal in cString---
 CMP fpString[6], 5
 JAE rounding_CS
 JB SET_CONVERSION
 
 rounding_CS:
 MOV AX, fpString[4]
 INC AX
 
 MOV fpString[4], AX
 
 JMP SET_CONVERSION
 
 
 SET_CONVERSION:
 XOR AX, AX
 MOV d_loopVar, AX
 
 MOV SI, 0
 MOV DI, 4
 
 CS_CONVERSION:
 MOV AX, fpString[SI]
 MOV BX, d_loopVar
 
 MUL tens[DI]
 
 ADD BX, AX
 MOV d_loopVar, BX
 
 ADD DI, 2
 ADD SI, 2
 
 CMP SI, 4 
 JBE CS_CONVERSION 
 JA POW_DIVISION
 
 
 ;---Division (1/powVar)---
 POW_DIVISION:
 XOR DX, DX
 XOR AX, AX
 MOV denomVar, AX
 
 MOV SI, 2
 MOV AX, 1000
 DIV d_loopVar
 MOV tempDP, DX
 
 ;----Divide 1 with pow VARIABLE---
 D_DIVISION:
 
 MUL tens[SI]
 ADD denomVar, AX
 
 MOV AX, tempDP
 MUL tens[6]
 DIV d_loopVar
 MOV tempDP, DX
 
 ADD SI, 2 
 
 CMP SI, 8
 JBE D_DIVISION
 JA D_ROUNDING
 
 ;---Check if 4th decimal need rounding----
 D_ROUNDING:
 XOR DX, DX
 
 MOV AX, denomVar
 DIV tens[6]
 MOV denomVar, AX
 
 CMP DX, 5
 JAE D_INCREMENT
 JB D_SUBTRACTION
 
 ;---Round off by incrementing denomVar---
 D_INCREMENT:
 
 MOV AX, denomVar
 INC AX
 MOV denomVar, AX
 JMP D_SUBTRACTION
 
 ;---Subtract denomVar with 1000 (1 - denomVar)---
 D_SUBTRACTION:
 
 MOV AX, tens[2]
 SUB AX, denomVar
 
 MOV denomVar, AX
 JMP numerator_Division
 
 ;====HARDEST PART!!=====(numerator / denominator)
 numerator_Division:
 XOR AX, AX
 XOR BX, BX
 XOR DX, DX
 
 MOV mLoanPayment, AX
 MOV mLoanPayment_DP, AX
 
 MOV SI, 2
 MOV AX, loanXinterest
 
 ;---DIVISION OF WHOLE NUMBER numerator
 LP_DIVISION:
 
 DIV denomVar
 MOV tempDP, DX
  
 MUL tens[SI]
 ADD mLoanPayment, AX
 
 MOV AX, tempDP
 MUL tens[6]
 
 ADD SI, 2
 
 CMP SI, 8
 JBE LP_DIVISION
 JA SET_DIVISION_DP
 
 ;----Continue division, storing the decimals values----
 SET_DIVISION_DP:
 
 XOR AX, AX
 XOR DX, DX
 MOV SI, 4
 
 DIVISION_DP:
 
 MOV AX, tempDP
 MUL tens[6]
 
 DIV denomVar
 MOV tempDP, DX
 
 MUL tens[SI]
 ADD mLoanPayment_DP, AX
 
 ADD SI, 2
 
 CMP SI, 8
 JBE DIVISION_DP
 JA SET_mLoanPaymentDP
 
 ;---DIVISION for mLoanPayment_DP---
 SET_mLoanPaymentDP:
 
 XOR AX, AX
 XOR DX, DX
 MOV SI, 0
 
 MOV AX, loanDP
 
 ;===DIVISION===
 DIV_mLoanPaymentDP:
 
 DIV denomVar
 MOV tempDP, DX
 
 MUL tens[SI]
 ADD mLoanPayment_DP, AX
 
 MOV AX, tempDP
 MUL tens[6]
 
 ADD SI, 2
 
 CMP SI, 8
 JBE DIV_mLoanPaymentDP
 JA upper_ROUNDING
                 
                 
 ;---Round off carry over decimals---
 upper_ROUNDING:
 
 MOV AX, mLoanPayment_DP
 DIV tens[2]
 
 MOV mLoanPayment_DP, DX
 
 CMP AX, 1
 JAE upper_increment
 JB mLP_ROUNDING
                 
                 
 upper_increment:
 MOV BX, mLoanPayment
 ADD BX, AX
 
 MOV mLoanPayment, BX
 JMP mLP_ROUNDING                 
                 
 ;---(Round off decimals to 2 d.p.)---
 mLP_ROUNDING:
 XOR DX, DX
 
 MOV AX, mLoanPayment_DP
 DIV tens[6]
 
 MOV mLoanPayment_DP, AX
 
 CMP DX, 5
 JAE mLP_INCREMENT
 JB RETURN_MLOAN
 
 ;---Increment decimal point by 1 after rounding off---
 mLP_INCREMENT:
 
 MOV AX, mLoanPayment_DP
 INC AX 
 
 MOV mloanPayment_DP, AX
 
 JMP RETURN_MLOAN
 
 

 ;========================================
 ;---RETURN FINAL MONTHLY LOAN PAYMENT----
 ;========================================
 RETURN_MLOAN:
 XOR DX, DX
 
 ;--Move mLoanPayment into outputVar(CAHNGE!)
 MOV AX, mLoanPayment
 MOV outputVar, AX
 
 
 ;--Split decimal point and move them--
 MOV AX, mLoanPayment_DP
 DIV tens[6]
 
 ADD dpString[0], AL
 ADD dpString[1], DL

 RET
_MONTHLY_LOAN ENDP 
;===============================

_logo proc ;------------------- PRINT LOGO (1 PAGE) >>> Press any key >>> cls
 
 CALL cls
    
;-------------------- PRINT LOGO

 LEA DX,logo01
 CALL print
 LEA DX,logo02
 CALL print
 LEA DX,logo03
 CALL print
 LEA DX,logo04
 CALL print
 LEA DX,logo05
 CALL print 
 LEA DX,logo06
 CALL print 
 LEA DX,logo07
 CALL print 
 LEA DX,logo08
 CALL print
 LEA DX,logo09
 CALL print 
 LEA DX,logo10
 CALL print 
 LEA DX,logo11
 CALL print 
 LEA DX,logo12
 CALL print 
 
;-------------------- END PRINT LOGO
 
 MOV AH,0
 INT 16H   
 
 CALL cls   
    
    
    RET
_logo ENDP    
    

           
end main
