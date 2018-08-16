.MODEL SMALL
.STACK 100
.DATA
                                                                                 
; =======================================================================================
; ====================== ERROR VARIABLES ================================================
; =======================================================================================

; TEMPORARY STACK CONTENT (STORES RETURN ADDRESS)
tempSP      DW  ?                                                                     
; *************************************************************
; *************************************************************
; *************************************************************
; ERROR FLAG (0 - NONE, 1 - errorStr1, 2 - errorStr2, etc.)
errorFlag   DB  ?                                                         
; *************************************************************
; *************************************************************
; *************************************************************
; ERROR MESSAGE TEST
errorStr1   db "EXCEPTION : CALCULATION OUT OF BOUND (ADDITION EXCEEDS 42949672.95)!$",10,13,24
errorStr2   db "EXCEPTION : INPUT OPERAND HIGHER THAN SUPPORTED VALUE(42949672.95)!$",10,13,24
errorStr3   db "EXCEPTION : UNSUPPORTED INPUT SYMBOL!$",10,13,24    
errorStr4   db "EXCEPTION : CALCULATION OUT OF BOUND (MULTIPLICATION OR POWER EXCEEDS 429496.7295)!$",10,13,24   
errorStr5   db "EXCEPTION : CALCULATION OUT OF BOUND (SUBTRACTION RETURNS NEGATIVE VALUE)!$",10,13,24          
errorStr6   db "EXCEPTION : MULTIPLE DOTS IN INPUT OPERAND!$",10,13,24   
;errorStr7   db "EXCEPTION : NUMBERS AFTER DECIMAL DOT EXCEEDS 5!$",10,13,24 ; <<<<< SOLVED   

; =======================================================================================
; ========================== EQUATION HANDLER VARIABLES =================================
; =======================================================================================

; -------- (ASCIITOHEX) ASCII INPUT TO HEX DOUBLE WORD -------- 
asciiIn     DB  "$$$$$$$$$$$"         ; ASCII INPUT (UNTOUCHED)  
; ASCII INPUT (ADDZEROS)
asciiInZ    DB  "$$$$$$$$$$$"
; ASCII INPUT (IN DECIMAL)
asciiInNum  DB  10 DUP(?)
; HEX OUTPUT (IN HEX DOUBLE WORD)
asciiHex    DW  0,0

; -------- (HEXTOASCII) HEX DOUBLE WORD TO ASCII OUTPUT -------
; HEX INPUT (IN HEX DOUBLE WORD)
hexIn       DW  ?,?
; HEX INPUT (TEMPORARY)
tempHex     DW  ?,?
; ASCII OUTPUT (IN STRINGS)
hexAscii    DB  11 DUP("$")

; -------- (ADDDOT) ADD DECIMAL DOT TO FINAL RESULT------------
; *************************************************************
; *************************************************************
; *************************************************************
asciiDot    DB  12 DUP("$")                      ; FINAL OUTPUT                                    
; *************************************************************
; *************************************************************
; *************************************************************

; ------- (ASCIITOHEX,HEXTOASCII) SHARED  ---------------------
; CURRENT INDEX OF ASCII INPUT IN DECIMAL STRING (EG '3' of '4321' IS INDEX 1)
zeroIndex   DW  ?
; PAIRS OF ZEROS IN DOUBLE WORD HEX, STARTING FROM 1,000,000,000 (15258,51712)          
zeroPairs   DW  15258,51712,1525,57600,152,38528,15,16960,1,34464,0,10000,0,1000,0,100,0,10,0,1

; ------------------ (IN2POST) INFIX TO POSTFIX ---------------                                    
; *************************************************************
; *************************************************************
; *************************************************************
; INFIX LIST        126 CHARACTERS LIMIT
inList      DB  127 DUP("$")                              
; *************************************************************
; *************************************************************
; *************************************************************
; POSTFIX LIST      126 CHARACTERS LIMIT
postList    DB  127 DUP("$")
; DOT TRIGGER 2 (TRIGGER 1 IF DECIMAL DOT EXISTS) (0 - NONE, 1 - EXISTS) 
dotTrigger2 DB  ?

; ------------------ (POSTOPS) POSTFIX EVALUATION -------------
; DOT TRIGGER (TRIGGER 1 IF DECIMAL DOT EXISTS) (0 - NONE, 1 - EXISTS, MORE THAN 1 - ERROR)
dotTrigger  DB  ?
; TEMP OPERAND STRING   (A DUPLICATION OF asciiIn FOR CLEAR BOUNDARIES BETWEEN 2 MAJOR FUNCTIONS)
tempOpStr   DB  "$$$$$$$$$$$"
; TEMP OPERAND HEX
tempOpHex   DW  0,0
; COUNT DECIMAL AFTER DOT
countPostDot    DB  0 
; postList INDEX
postSI      DW  0
; tempOpStr INDEX
tempDI      DW  0
; TEMPORARY NUMBER
tempNum     DW  0,0
; tempCX
tempCX      DW  ?
; ------------------ (dpConvert) DECIMAL POINT CONVERTER, CONVERT 0 OR 1 DP TO 2 DP (RUN TWICE FOR 0DP to 2DP) ----------------------
dpConv      DW  0,0

                                                                                
; =======================================================================================
; ========================= OPERATOR VARIABLES ==========================================
; =======================================================================================

;GENERAL VARIABLES
num1    dw 0000H, 0000H
num2    dw 0000H, 0000H
ans     dw 0000H, 0000H

;POWER FUNCTION VARIABLES
pow_counter dw ?
pow_of dw 0
temp_pow dw 0, 0

;Division variables
tens    dw      10d, 100d, 1000d
rmdr    dw      ?
temp_rmdr dw    ?
temp_dp dw      0000h, 0000h
dp      db      0, 0

; SQRT variables
int32 dd 0
squareRoot dw ?

; =======================================================================================
; ========================= OLD CODES VARIABLES =========================================
; =======================================================================================

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

    logo11  db 10,13,"                       @ .      WOLFE'S CALCULATOR     # @@"
            db 10,13,"                         @                            @@@"
            db "$"

    logo12  db 10,13,"                          . @(                     @@"
;            db 10,13,"                           Press any key to continue..."
			db 10,13,"                              *@.@@ @@ @@ @@ @@@*@"
            db "$"

;---------------------------------------------------------------------------------------


; =======================================================================================
; ================================ UI VARIABLES =========================================
; =======================================================================================
; Share variable --------------------------------------------------------------
    e db "2.718"                ; value of exp 
    pi db "3.142"               ; value of pi
; Mouse Variables -------------------------------------------------------------
    Mode db 0                   ; 0 - keyboard, 1 - mouse          
    ; constant for dx
    start_Row db 38h               ; top left corner as starting box edge
    end_Row db 47h                 ; end corner  
    ; constant for cx 
    start_Col dw 0010h
    end_Col dw 0067h               ;0067h               
; Calculator UI ---------------------------------------------------------------       
    File db "Calc_UI.txt", 0    ; CALCULATOR UI with symbols
    Testing db "Txt.txt", 0     ; for testing
    Handle dw ?               
    ScanLength dw 1C0h          ; 448d  
    scanf db 1000 dup("$")      ; collect lines to print 
; Change Row and Column area here ---------------------------------------------
    Row dw 0200h                ; Updates row positions    (buttons)
    Col dw 000Ah                ; Updates column positions (buttons)    
    Update_Col db ?             ; Update display to left  
    String_x db 4Ah             ; Every key registered will shift to left
    String_y db 03h             ; Constant Row 
; Button Variable ------------------------------------------------------------- 
    Input db ?                  ; enter keys for input 1 byte 
    upperIn db ?                ; keys that stored in AH  
    Bool db ?                   ; Constraint checking
; String Variable -------------------------------------------------------------        
    tempStr db 71 dup("$")      ; temporarily holds string
    String db 101 dup("$")      ; accept keys           
    inLimit dw 70d              ; limit for input, word size for 16 bit reg
    ; Pointer                                          
    StringPtr dw ?              ; String Pointer
    inPtr dw ?                  ; input string pointer     
    tPtr db ?                   ; pointer that indicates length of a term 
    ; Bool
    DigitF db ?                 ; bool variable for checking zero as front digit
    opF db 1                    ; number of operand typed only once per term
; Error display ---------------------------------------------------------------
    Math_Err db "Math Error!$"
    Syntax_Err db "Syntax Error!$"  
; Symbol UI for frame ---------------------------------------------------------  
    ScreenUI db "Calculator", 13, 10, 201d, 4Dh dup(205d), 187d, 13, 10
             db 186d, 4Dh dup(20h), 186d, 13, 10
             db 186d, 4Dh dup(20h), 186d, 13, 10
             db 186d, 4Dh dup(20h), 186d, 13, 10
             db 200d, 4Dh dup(205d), 188d, 13, 10, 41h dup(20h), "Mode:$"
    str0 db "Keyboard$"
    str1 db "Mouse   $"                 
; View Textfile for button position -------------------------------------------    
    array_button dw 1F73h, 075Eh, 264Ch, 011Bh, 326Dh
                 dw 1071h, 1F53h, 2E43h, 1454h, 2348h
                 dw 1749h, 2E63h, 2247h, 0E08h, 352Fh 
                 dw 1265h, 0837h, 0938h, 0A39h, 2D78h
                 dw 1970h, 0534h, 0635h, 0736h, 0C2Dh          
                 dw 0221h, 0231h, 0332h, 0433h, 0D2Bh
                 dw 0A28h, 0B29h, 0B30h, 342Eh, 1C0Dh                   

    ; BH = 8F, 80h causes blinking screen
    ; 25 row and 80 column max 
    ; max cursor range cx: column 027Fh dx: row 0C7h
    
    ; FACTORIAL, M+, SIN, COS, TAN 
    ; remember to enable sqrt 
    color db 0eh  
    ; display variable
    coordxy dw 160, 100             ; coordinate for center x, y
    scr_y dw 100 
    scr_x dw 160  
    Def_size dw 320  
      
; Input Variable =========================================================== 
    gradient_sign dw 1                  ; sign of gradient           
    gradient dw 1                  ; gradient of the line
    x dw -60                        ; starting point of 'x'
    times dw 1                      ; this is a skalar y=kx, which 
    Inv_x dw 1                      ; 1/x
    exp dw 1                        ; x^n , n = 1,2,3  
    
; Variables ================================================================== 
    x_axis dw ?                     ; x axis always double value of x 
    pow_x dw ?
    
; Power Graph ===============================================================
    iBase dw 1                      ; Z base (with sign) 
    base dw ?                       ; base number n^x 
    baseSign dw 1                   ; base sign
    ExpDiv dw 1                     ; e^x/n
    ExpSign dw 1                    ; sign for exp   
;Input =======================================================================    
    xFlag db 0                      ; use X only once 
    errBool db 0                    ; error flag in graph
    
    ARRAY LABEL BYTE
    max db 16
    act db ?
    Formula db 16 dup ("$")         ; enter equation 
    Buffer db 16 dup ("$")          ; clear formula 
    
    err db 40 dup (20h), "Check input error for invalid syntax!", 5 dup (20h), "$"
    Cont db 40 dup (20h), "Press q to exit, press any key to continue.$" 
    
    SineApprox db "x-(x^3)/6+(x^5)/120-(x^7)/5040$" 
    Value db 9 dup ("$")  
    Radian db "x3.142/180$"  
    RadianValue db 9 dup ("$") 
    ValueSize dw ? 
    RadianVSize db ?     
    tempPtr dw ?    
    
    directOut db ?
    
    ; Polynomial a(x+b)+c
    ;C dw ?                          ;y=+C
    ;b dw ?                          ;y=bX
    ;term db ?                       ; X^3+X, 2 terms    
                    
    ; do times dw 3, 50, 210        and times[di]   
    ; x range up to -20~20, -60~60 ,-25~25 
    ; n^x x: -10, times : 100,         
    
    ; make a function that compares sign of exp(+/- x) and a variable to jump
.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    
; START SETUPS--------------------------------------    
    call cls
    call _Calc_UI              
    call _Calculator            ; Begins here
	
	EXIT:
	
	CALL _logo
			  
    MOV AX,4C00H
    INT 21H

MAIN ENDP

; ============================ UI-OPERATION BRIDGE ===============================
UIMERGE PROC 
    
    call Trigonometry
    
    cmp directOut, 1
    je toPrint
               
    xor si, si

    XOR CX,CX
    XOR BX,BX
    XOR DI,DI
             
    MOV CX,70
             
    MERGE_INTRANSFER:    ; TRANSFER String TO inList
        MOV BL,String[DI]                                  ; TEMPORARY TESTING
        MOV inList[DI],BL
        INC DI
        LOOP MERGE_INTRANSFER
    
    CALL CLREG
    
    CALL IN2POST
	
	CALL POSTOPS
    
    CALL HEXTOASCII
    
    CALL ADDDOT

toPrint:
    and directOut, 0
     
    std       
    xor si, si                                    
LEN:      
    mov al, asciiDot[si]
    inc si
    
    cmp al, "$"
    jne LEN
    
    mov bx, si
    sub bx, 2
      
    mov dh, String_y
    mov dl, String_x
    
    inc dh
    sub dl, bl
    call cursor 
    
    LEA DX,asciiDot
    call print
    
    CALL CLREG 
    
    cmp Mode, 0               ; FIX PROBLEM ERHERE  
    jz KeyB

Buffering:
    mov ax, 3                 ; get buttons
    int 33h   
    
    test bl,1                 ; AND bits with 0000 0001
    jnz Return
    test bl,2                 ; AND bits with 0000 0010        
    jnz Return
    
    jmp Buffering
  
KeyB:    
    mov ah, 1
    int 21h
    
Return:    
    call clrEntry 

    RET
UIMERGE ENDP


; ====================== ERROR ================================================

ERROR_MSG PROC

XOR BX,BX
MOV BL,errorFlag
CMP BX,1
JE ERROR_MSG1
CMP BX,2
JE ERROR_MSG2
CMP BX,3
JE ERROR_MSG3
CMP BX,4
JE ERROR_MSG4
CMP BX,5
JE ERROR_MSG5
CMP BX,6
JE ERROR_MSG6
;CMP BX,7
;JE ERROR_MSG7

ERROR_MSG1:
mov ah, 09H
lea dx, errorStr1
int 21H
JMP ERROR_EXIT

ERROR_MSG2:
mov ah, 09H
lea dx, errorStr2
int 21H
JMP ERROR_EXIT

ERROR_MSG3:
mov ah, 09H
lea dx, errorStr3
int 21H
JMP ERROR_EXIT

ERROR_MSG4:
mov ah, 09H
lea dx, errorStr4
int 21H
JMP ERROR_EXIT

ERROR_MSG5:
mov ah, 09H
lea dx, errorStr5
int 21H
JMP ERROR_EXIT

ERROR_MSG6:
mov ah, 09H
lea dx, errorStr6
int 21H
JMP ERROR_EXIT

;ERROR_MSG7:
;mov ah, 09H
;lea dx, errorStr7
;int 21H
;JMP ERROR_EXIT

ERROR_EXIT:
ret 
ERROR_MSG ENDP

; CLEAR ALL GENERAL REGISTERS ------------------------------------------------------------------
CLREG PROC
    XOR AX,AX
    XOR BX,BX
    XOR CX,CX
    XOR DX,DX
    XOR SI,SI
    XOR DI,DI
    XOR BP,BP
    RET    
CLREG ENDP

; =========================== EQUATION HANDLER ======================================

; INFIX TO POSTFIX GENERAL FUNCTION
IN2POST PROC
    CALL CLREG
    
    MOV tempSP,SP
    
    XOR AX,AX
    MOV AL,40
    
    PUSH AX ; PUSH INITIAL PARENTHESIS "("
    
    XOR AX,AX
    
    MOV dotTrigger2,AL
    MOV errorFlag,AL
    
    MOV SI,0
    MOV DI,0
    
    ; GENERAL CHAR CHECKING
    I2P_L1:
        MOV AL,inList[SI]
        
        CMP AX,36           ; $
        JE E_I2P_RIGHTP
        CMP AX,32           ; space
        JE E_I2P_SKIP
        CMP AX,40           ; (
        JE E_I2P_LEFTP        
        CMP AX,41           ; )
        JE E_I2P_RIGHTP       
        CMP AX,43           ; +
        JE E_I2P_OPERATOR
        CMP AX,45           ; -
        JE E_I2P_OPERATOR
        CMP AX,120          ; x
        JE E_I2P_OPERATOR
        CMP AX,33           ; !
        JE E_I2P_OPERATOR
        CMP AX,47           ; /
        JE E_I2P_OPERATOR
        CMP AX,115          ; s (squared)
        JE E_I2P_OPERATOR
        CMP AX,94           ; ^ (power)
        JE E_I2P_OPERATOR
        CMP AX,113          ; q (square root)
        JE E_I2P_OPERATOR
        CMP AX,46           ; . (decimal dot)
        JE E_I2P_OPERAND
        CMP AX,48           ; operands
        JB E_I2P_INVALID2
        CMP AX,57           ; operands
        JA E_I2P_INVALID2
        JMP I2P_OPERAND
        
		E_I2P_RIGHTP:
			JMP I2P_RIGHTP
		
        E_I2P_SKIP:
            JMP I2P_SKIP
            
        E_I2P_LEFTP:
            JMP I2P_LEFTP
            
        E_I2P_OPERATOR:
            JMP I2P_OPERATOR
            
        E_I2P_OPERAND:
            JMP I2P_OPERAND
            
        E_I2P_INVALID2:
            JMP I2P_INVALID2
        
        I2P_OPERAND:
        XOR BP,BP
        MOV BL,123          ; ADD OPERAND OPENING {
        MOV postList[DI],BL
        INC DI              ; FORWARD postList
        
        I2P_OPERAND2:
            MOV postList[DI],AL ; ADD OPERAND
            INC DI              ; FORWARD postList  
            
            INC SI              ; FORWARD inList
            MOV AL,inList[SI]
        
            INC BP              ; BP IS OPERAND CURRENT LENGTH (INCLUDING DOT)
            
            XOR DX,DX
            MOV DL,dotTrigger2
            CMP DX,1
            JE I2P_OPERANDLENGTH2
            
            ; I2P_OPERANDLENGTH1
                CMP BP,10
                JA E_I2P_INVALID
                JMP I2P_OPERAND21
                
            I2P_OPERANDLENGTH2:
                CMP BP,11
                JA E_I2P_INVALID
                JMP I2P_OPERAND21
				
			E_I2P_INVALID:
				JMP I2P_INVALID
                
        ; CHECK NEXT CHAR FOR OPERAND
        I2P_OPERAND21:
            CMP AX,46           ; dot
            JE I2P_OPERANDDOT                
            CMP AX,48           ; operands
            JB I2P_OPERANDOUT
            CMP AX,57           ; operands
            JA I2P_OPERANDOUT
        
            JMP I2P_OPERAND2
            
            I2P_OPERANDDOT:
                XOR DX,DX
                MOV DL,1
                MOV dotTrigger2,DL
                JMP I2P_OPERAND2
            
            I2P_OPERANDOUT:
                MOV BL,125      ; ADD OPERAND CLOSING }
                MOV postList[DI],BL 
                INC DI          ; FORWARD postList
                JMP I2P_L1
        
        I2P_LEFTP:
            PUSH AX
            INC SI              ; FORWARD inList
            JMP I2P_L1
         
        I2P_RIGHTP:
            POP BX            
            CMP BX,40           ; CHECK FOR (
            JE I2P_RIGHTPOUT
            
            MOV postList[DI],BL ; ADD OPERATOR TO postList
            INC DI              ; FORWARD postList
            JMP I2P_RIGHTP
            
            
            I2P_RIGHTPOUT:      ; IF ( THEN EXIT LOOP         
                CMP AX,36       ; IF $ THEN EXIT MAIN LOOP
                JE E_I2P_EXIT
                INC SI          ; FORWARD inList
                JMP I2P_L1
                
                E_I2P_EXIT:
                    JMP I2P_EXIT
                
        I2P_OPERATOR:
            POP BX  
            
            CMP AX,115          ; s
            JE I2P_PREC11
            CMP AX,94           ; ^
            JE I2P_PREC11
            CMP AX,113          ; q
            JE I2P_PREC11
            CMP AX,120          ; x
            JE I2P_PREC10
            CMP AX,33           ; !
            JE I2P_PREC10
            CMP AX,47           ; /
            JE I2P_PREC10
            CMP AX,43           ; +
            JE I2P_PREC09
            CMP AX,45           ; -
            JE I2P_PREC09
                        
            I2P_PREC09:         ; PRECEDENCE LEVEL 09 : + -    
                CMP BX,43
                JE I2P_APPEND
                CMP BX,45
                JE I2P_APPEND
                
            I2P_PREC10:         ; PRECEDENCE LEVEL 10 : x ! /   
                CMP BX,120
                JE I2P_APPEND
				CMP BX,33
				JE I2P_APPEND
                CMP BX,47
                JE I2P_APPEND   
                
            I2P_PREC11:         ; PRECEDENCE LEVEL 11 : s ^ q    
                CMP BX,115
                JE I2P_APPEND
                CMP BX,94
                JE I2P_APPEND
                CMP BX,113
                JE I2P_APPEND
                PUSH BX
                JMP I2P_OPERATOROUT
                
                I2P_APPEND:
                    MOV postList[DI],BL
                    INC DI
                    JMP I2P_OPERATOR
            
            
            I2P_OPERATOROUT:
                CMP AX,115          ; s
                JE I2P_SQUARED
                CMP AX,113          ; q
                JE I2P_SQRT
				CMP AX,33			; !
				JE I2P_FACTORIAL
                JMP I2P_OPERATOROUT2
                
                I2P_SQUARED:    ; ADD {2} TO postList FOR SQUARED
                    MOV DX,123
                    MOV postList[DI],DL
                    INC DI
                    MOV DX,50   ; 2 IN ASCII    
                    MOV postList[DI],DL
                    INC DI
                    MOV DX,125
                    MOV postList[DI],DL
                    INC DI
                    JMP I2P_OPERATOROUT2
                
                I2P_SQRT:       ; ADD {2} TO postList FOR SQUARED and FACTORIAL (2 IS ACTUALLY A DUMB VALUE)
                    MOV DX,123
                    MOV postList[DI],DL
                    INC DI
                    MOV DX,50   ; 2 IN ASCII    
                    MOV postList[DI],DL
                    INC DI
                    MOV DX,125
                    MOV postList[DI],DL
                    INC DI
                    JMP I2P_OPERATOROUT2 
					
				 I2P_FACTORIAL:       ; ADD {2} TO postList FOR SQUARED and FACTORIAL (2 IS ACTUALLY A DUMB VALUE)
                    MOV DX,123
                    MOV postList[DI],DL
                    INC DI
                    MOV DX,50   ; 2 IN ASCII    
                    MOV postList[DI],DL
                    INC DI
                    MOV DX,125
                    MOV postList[DI],DL
                    INC DI
                    JMP I2P_OPERATOROUT2
            
            I2P_OPERATOROUT2:
                PUSH AX
                INC SI 
                JMP I2P_L1    
                
    
    I2P_SKIP:
        INC SI
        JMP I2P_L1
        
    I2P_INVALID:
        mov ax,2
        mov errorFlag,al
    
        MOV SP,tempSP
        
        JMP I2P_EXIT
   
    I2P_INVALID2:
        mov ax,3
        mov errorFlag,al
    
        MOV SP,tempSP
        
        JMP I2P_EXIT
       
    I2P_EXIT:     
        
        ; CLEAR inList TO GET READY FOR REUSE
        MOV CX,127
        MOV SI,0
        MOV AX,36
            I2P_CLIN:
                MOV inList[SI],AL
                INC SI
                LOOP I2P_CLIN
        
        CALL CLREG
        
        RET    
        
IN2POST ENDP


; POSTFIX EVALUATION GENERAL FUNCTION
; (ORGANISATION OF OPERATIONS)

POSTOPS PROC
    CALL CLREG
    
    MOV tempSP,SP
    
    MOV SI,0
    MOV postSI,SI
    
    PO_L1:                  ; IMPORTANT : FROM HERE ON DO NOT CLEAR AX AND SI
        XOR AH,AH
        MOV errorFlag,AH
        MOV SI,postSI
        MOV AL,postList[SI]                         
        
        CMP AX,36           ; $
        JE E_PO_END
        CMP AX,43           ; +
        JE E_PO_OPERATOR
        CMP AX,45           ; -
        JE E_PO_OPERATOR
        CMP AX,120          ; x
        JE E_PO_OPERATOR
        CMP AX,33           ; !
        JE E_PO_OPERATOR
        CMP AX,47           ; /
        JE E_PO_OPERATOR
        CMP AX,115          ; s (squared)
        JE E_PO_OPERATOR
        CMP AX,94           ; ^ (power)
        JE E_PO_OPERATOR
        CMP AX,113          ; q (square root)
        JE E_PO_OPERATOR    
        JMP PO_OPENING
        
        E_PO_END:
            JMP PO_END
        
        E_PO_OPERATOR:
            JMP PO_OPERATOR
        
        ; WILL MEET OPERAND OPENING {
        ; HENCE,
        
        PO_OPENING:
        
            MOV CX,11
            XOR DI,DI
            MOV BX,36
            
            
            PO_CLEARSTR1:           ; CLEAR tempOpStr
                MOV tempOpStr[DI],BL
                INC DI
                LOOP PO_CLEARSTR1
            
            XOR DX,DX               ; CLEAR tempOpHex
            MOV tempOpHex[0],DX
            MOV tempOpHex[2],DX
                
            ; DO NOT USE BX OTHER THAN countPostDot
            MOV DI,0
            MOV tempDI,DI
            XOR BX,BX
            XOR DX,DX
            MOV dotTrigger,DL       ; RESET DOT TRIGGER (0 - NONE, 1 - EXISTS, MORE THAN 1 - ERROR)
            MOV countPostDot,DL     ; RESET DECIMAL COUNT AFTER DOT
            
            INC SI                  ; SKIP OPERAND OPENING {
            MOV postSI,SI
            
            PO_NUMBERS:
                XOR AH,AH
                MOV SI,postSI
                MOV AL,postList[SI]
                
                ; CHECK FOR } and .
                
                CMP AX,125          ; OPERAND CLOSING }
                JE PO_CLOSING 
                CMP AX,46           ; DECIMAL DOT .
                JE PO_DOT
                
                ; IF NOT } AND .
                MOV DI,tempDI
                MOV tempOpStr[DI],AL; INSERT TO TEMP OPERAND STRING
                INC DI
                MOV tempDI,DI
                
                XOR DX,DX
                MOV DL,dotTrigger
                CMP DX,0
                JBE PO_SKIPADDDOT
                
                INC BL
                MOV countPostDot,BL ; ADD COUNT FOR DECIMAL AFTER DOT
            
            PO_SKIPADDDOT:          ; NO DECIMAL
                
                INC SI              ; FORWARD postList
                MOV postSI,SI
                JMP PO_NUMBERS
                
            PO_DOT:
                XOR DX,DX
                MOV DL,dotTrigger
                CMP DL,0            ; DETECTS MULTIPLE DOTS AND PROMPT ERROR
                JA E_PO_DOTERROR
                
                MOV DX,1            ; DOT DETECTED
                MOV dotTrigger,DL
                
                XOR DX,DX
                
                INC SI              ; FORWARD postList
                MOV postSI,SI
                JMP PO_NUMBERS
                
                E_PO_DOTERROR:
                    XOR DX,DX
                    MOV DL,6
                    MOV errorFlag,DL
                    JMP PO_ERROR
                
            PO_CLOSING:
                ; TRANSFER TO asciiIn
                MOV CX,11
                XOR DI,DI
                XOR DX,DX

                PO_TRANSFERSTR1:    ; TRANSFER tempOpStr TO asciiIn
                    MOV BL,tempOpStr[DI]
                    MOV asciiIn[DI],BL
                    INC DI
                    LOOP PO_TRANSFERSTR1
                
                CALL ASCIITOHEX     ; ALL REGISTERS ARE CLEARED RIGHT AFTER CALL
                
                MOV DX,asciiHex[0]
                MOV tempOpHex[0],DX
                MOV DX,asciiHex[2]
                MOV tempOpHex[2],DX
                
                XOR DX,DX
                
                MOV DX,tempOpHex[0]
                MOV dpConv[0],DX
                MOV DX,tempOpHex[2]
                MOV dpConv[2],DX
                
                XOR DX,DX
                
                MOV BL,countPostDot
                CMP BL,0            ; NO DP
                JE PO_0DP
                CMP BL,1            ; 1 DP
                JE PO_1DP
                CMP BL,2            ; 2 DP
                JE PO_2DP
;                CMP BL,5            ; MORE THAN 5 DIGITS
;                JA E_PO_DECIMALERROR
                JMP PO_xDP
                
;                E_PO_DECIMALERROR:
;                    XOR DX,DX
;                    MOV DL,7
;                    MOV errorFlag,DL
;                    JMP PO_ERROR
                
                PO_xDP:             ; MORE THAN 3 DIGITS
                    XOR CX,CX
                    MOV tempCX,CX
                    SUB BL,2
                    MOV CL,BL
                    MOV tempCX,CX
                    PO_xDPL1:
                        MOV tempCX,CX
                        MOV DX,tempOpHex[0]
                        MOV num1[0],DX
                        MOV DX,tempOpHex[2]
                        MOV num1[2],DX
                        XOR DX,DX
                        MOV num2[0],DX
                        MOV num2[2],1000
                        CALL division
                        MOV DX,ans[0]
                        MOV tempOpHex[0],DX
                        MOV DX,ans[2]
                        MOV tempOpHex[2],DX
                        XOR DX,DX
                        MOV CX,tempCX
                        LOOP PO_xDPL1
                    JMP PO_xDPEXIT                        
                
                PO_0DP:             ; ADD ZEROS (CONVERT TO 2DP)
                    CALL dpConvert
                    xor dx,dx
                    mov dl,errorFlag
                    cmp dl,0
                    jne e_po_error
					jmp PO_1DP
					
					e_po_error:
						jmp po_error
                
                PO_1DP:             ; ADD ZEROS (CONVERT TO 2DP)
                    CALL dpConvert 
                    xor dx,dx
                    mov dl,errorFlag
                    cmp dl,0
                    jne e_po_error
                
                PO_2DP:             ; PUSH TO STACK (TWICE)
                    MOV DX,dpConv[0]
                    MOV tempOpHex[0],DX
                    MOV DX,dpConv[2]
                    MOV tempOpHex[2],DX
                
                    XOR DX,DX
                
                PO_xDPEXIT:    
                    MOV DX,tempOpHex[2]
                    PUSH DX
                    MOV DX,tempOpHex[0]
                    PUSH DX 
                    
                    MOV SI,postSI
                    INC SI          ; FORWARD postList
                    MOV postSI,SI
                    JMP PO_L1
                
            
        PO_OPERATOR:    
            XOR BX,BX
            POP BX
            MOV num2[0],BX
            XOR BX,BX
            POP BX
            MOV num2[2],BX
            XOR BX,BX
            POP BX
            MOV num1[0],BX
            XOR BX,BX
            POP BX
            MOV num1[2],BX
            
            XOR BX,BX
            
            CMP AX,43           ; +
            JE PO_ADDITION
            CMP AX,45           ; -
            JE PO_SUBTRACT
            CMP AX,120          ; x
            JE PO_MULTIPLY
            CMP AX,33           ; !
            JE PO_FACTORIAL
            CMP AX,47           ; /
            JE E_PO_DIVISION
            CMP AX,115          ; s (squared)
            JE E_PO_POWER
            CMP AX,94           ; ^ (power)
            JE E_PO_POWER
            CMP AX,113          ; q (square root)
            JE E_PO_SQRT
            JMP PO_ADDITION
            
            E_PO_SQRT:
                JMP PO_SQRT
				
			E_PO_DIVISION:
				JMP PO_DIVISION
			
			E_PO_POWER:
				JMP PO_POWER
            
            ; FROM HERE ON AX IS REPLACED BY OPERATOR FUNCTIONS
            
            PO_ADDITION:
                CALL addition
                JMP PO_OPERATOROUT
                
            PO_SUBTRACT:
                CALL subtract
                JMP PO_OPERATOROUT      
            
            PO_MULTIPLY:
                CALL multiply
                MOV BX,ans[2]
                MOV num1[2],BX
                MOV BX,ans[0]
                MOV num1[0],BX
                MOV num2[0],0
                MOV num2[2],10000
                XOR BX,BX
                CALL division
                JMP PO_OPERATOROUT
            
			PO_FACTORIAL:
				MOV BX,num1[0]
				CMP BX,0
				JNE E_PO_FACTORIALOVER
				MOV BX,num1[2]
				CMP BX,0
				JE E_PO_FACTORIALZERO
				
				MOV BX,num1[0]
				MOV tempNum[0],BX
				MOV BX,num1[2]
				MOV tempNum[2],BX
				JMP PO_FACTORIALOP1
				
				E_PO_FACTORIALOVER:
					JMP PO_FACTORIALOVER
					
				E_PO_FACTORIALZERO:
					JMP PO_FACTORIALZERO
				
				PO_FACTORIALOP1:
					; num2 MINUS 1
					MOV BX,tempNum[0]
					MOV num2[0],BX
					MOV BX,tempNum[2]
					SUB BX,100
					CMP BX,100
					JLE E_PO_OPERATOROUT2
					MOV num2[2],BX
					MOV tempNum[2],BX
					MOV BX,num2[0]
					MOV tempNum[0],BX
					; multiply
				
					CALL multiply
					MOV BX,ans[2]
					MOV num1[2],BX
					MOV BX,ans[0]
					MOV num1[0],BX
					MOV num2[0],0
					MOV num2[2],10000
					XOR BX,BX
					CALL division
					MOV BX,ans[2]
					MOV num1[2],BX
					MOV BX,ans[0]
					MOV num1[0],BX
					JMP PO_FACTORIALOP1
					
					E_PO_OPERATOROUT2:
						MOV BX,num1[2]
						MOV ans[2],BX
						MOV BX,num1[0]
						MOV ans[0],BX
						JMP PO_OPERATOROUT
				
				PO_FACTORIALOVER:
					MOV BX,0
					MOV ans[0],BX
					MOV ans[2],BX
					MOV BX,4
					MOV errorFlag,BL
					JMP PO_OPERATOROUT
				
				PO_FACTORIALZERO:
					MOV BX,100
					MOV ans[2],BX
					MOV BX,0
					MOV ans[0],BX
					JMP PO_OPERATOROUT
			
            PO_DIVISION:
                CALL division
                JMP PO_OPERATOROUT
                
            PO_POWER:
                MOV BX,num1[0]
                MOV tempNum[0],BX
                MOV BX,num1[2]
                MOV tempNum[2],BX
                MOV BX,num2[0]
                MOV num1[0],BX
                MOV BX,num2[2]
                MOV num1[2],BX
                MOV BX,10000
                MOV num2[2],BX
                MOV BX,0
                MOV num2[0],BX
                CALL division
                MOV BX,ans[0]
                MOV num2[0],BX
                MOV BX,ans[2]
                MOV num2[2],BX
                MOV BX,tempNum[0]
                MOV num1[0],BX
                MOV BX,tempNum[2]
                MOV num1[2],BX
                MOV BX,num2[2]
                MOV pow_of,BX
                CALL power                     
                JMP PO_OPERATOROUT
                
            PO_SQRT:
                CALL sqrt
                JMP PO_OPERATOROUT     
            
            PO_OPERATOROUT:
			
				MOV BX,0
				MOV tempNum[0],BX
				MOV tempNum[2],BX
				
                xor dx,dx
                mov dl,errorFlag
                cmp dl,0
                jne po_error
                 
                MOV BX,ans[2]
                PUSH BX
                MOV BX,ans[0]
                PUSH BX   
                
                MOV SI,postSI
                INC SI
                MOV postSI,SI
                JMP PO_L1    
             
        
        PO_ERROR:
            MOV SP,tempSP
            
            JMP PO_END2
            
        PO_END:
            POP AX              ; FINAL ANSWER
            MOV hexIn[0],AX
            POP AX
            MOV hexIn[2],AX
        
        PO_END2:    
            ; CLEAR postList    
            MOV CX,127
            MOV SI,0
            MOV AX,36
            PO_CLPOST:
                MOV postList[SI],AL
                INC SI
                LOOP PO_CLPOST
        
        CALL CLREG
            
        
        RET
POSTOPS ENDP

; DECIMAL POINT CONVERTOR
dpConvert PROC
xor ax, ax
xor bx, bx

mov ax, dpConv[2]
mov bx, dpConv[0]

mov num1[0], bx
mov num1[2], ax

xor ax, ax
mov bx, 10d

mov num2[0], ax
mov num2[2], bx

call multiply
xor dx,dx
mov dl,errorFlag
cmp dl,0
jne dp_error                  

mov ax, ans[0]
mov bx, ans[2]

mov dpConv[0], ax
mov dpConv[2], bx

dp_exit:

ret

dp_error:
xor dx,dx
mov dl,2
mov errorFlag,dl

ret
dpConvert ENDP 

; ASCII STRING TO HEXADECIMAL DOUBLE WORD (STORED IN TWO WORDS) --------------------------------

ASCIITOHEX PROC 
    
    CALL CLREG
    
    CALL ADDZEROS

    CALL CLREG
                   
    CALL ASCIITONUM
	
	CALL CLREG
	
	CALL ZEROLOOPER
	
	CALL CLREG
	
	RET
ASCIITOHEX ENDP

ASCIITONUM PROC

    MOV SI,0
        
        ASCII2NUM:        
    
        MOV AL,asciiInZ[SI]
        SUB AL,30H
        MOV asciiInNum[SI],AL
    
        INC SI
        
        CMP SI,10
        JB ASCII2NUM
    RET
ASCIITONUM ENDP

ZEROLOOPER PROC
    ;INSERT INDEX HERE (CHANGE '0' TO VARIABLE)
	MOV SI,0	       
	
	; CLEAR asciiHex
	MOV asciiHex[0],SI
	MOV asciiHex[2],SI
	
	ZERO:
	MOV CL,asciiInNum[SI]
	CMP CL,0
	JBE NEXT
	CMP CL,9
	JA NEXT
	JBE ZEROSOP
	
	NEXT:
	    INC SI
	    JMP ZERO
	
	ZEROSOP:    
	CMP SI,0
	JE ZERO9    
	CMP SI,1
	JE ZERO8    
	CMP SI,2
	JE ZERO7    
	CMP SI,3
	JE ZERO6    
	CMP SI,4
	JE ZERO5    
	CMP SI,5
	JE ZERO4    
	CMP SI,6
	JE ZERO3    
	CMP SI,7
	JE ZERO2    
	CMP SI,8
	JE ZERO1
	CMP SI,9
	JE REMAIN    
	JMP EXITZEROLOOPER    
	    
	    
	ZERO9:
	    MOV zeroIndex,0
	    JMP ZEROSLOOP
	
	ZERO8:
	    MOV zeroIndex,4
	    JMP ZEROSLOOP
	
	ZERO7:
	    MOV zeroIndex,8
	    JMP ZEROSLOOP
	
	ZERO6:
	    MOV zeroIndex,12
	    JMP ZEROSLOOP
	
	ZERO5:
	    MOV zeroIndex,16
	    JMP ZEROSLOOP
	    
	ZERO4:
	    MOV zeroIndex,20
	    JMP ZEROSLOOP
	
	ZERO3:
	    MOV zeroIndex,24
	    JMP ZEROSLOOP
	
	ZERO2:
	    MOV zeroIndex,28
	    JMP ZEROSLOOP
	
	ZERO1:
	    MOV zeroIndex,32
	    JMP ZEROSLOOP
	
	REMAIN:
	    MOV zeroIndex,36
	    JMP ZEROSLOOP
	    
	ZEROSLOOP:
	    MOV DX,asciiHex[2]
	    MOV DI,asciiHex[0]
	    MOV BX,zeroIndex
	    ADD DX,zeroPairs[BX+2]
	    ADC DI,zeroPairs[BX]
	    MOV asciiHex[2],DX
	    MOV asciiHex[0],DI
	    LOOP ZEROSLOOP
	    INC SI
	    JMP ZERO
	
	EXITZEROLOOPER:    
	    
        RET

ZEROLOOPER ENDP

; ADD REQUIRED ZEROS TO ASCII INPUT FOR ASCIITOHEX ---------------------------------------------
ADDZEROS PROC
	
	CALL CLREG
	
	MOV SI,0
	A_COUNTZEROS:
	    MOV AL,asciiIn[SI]
	    INC SI
	    CMP AL,36
	    JNE A_COUNTZEROS
	
	    MOV BX,11
	    SUB BX,SI
	    MOV DX,BX
	    MOV CX,SI
	    MOV SI,0
	    A_TRANSFER:
	        MOV AL,asciiIn[SI]
	        MOV asciiInZ[BX],AL
	        INC SI
	        INC BX
	        LOOP A_TRANSFER
	    
	    MOV CX,DX
	    MOV SI,0
	    CMP CX,0
	    JE A_EXIT
	    A_REZEROS:
	        MOV asciiInZ[SI],48
	        INC SI
	        LOOP A_REZEROS    
	    
	    A_EXIT:
	    
	    CALL CLREG
	    
	    RET
ADDZEROS ENDP

; HEXADECIMAL DOUBLE WORD (STORED IN TWO WORDS) TO ASCII STRING --------------------------------

HEXTOASCII PROC
    
    CALL CLREG
    
    ; CLEAR hexAscii
    MOV CX,11
    MOV SI,0
    H_CLHEXASCII:
        MOV hexAscii[SI],36
        INC SI
        LOOP H_CLHEXASCII
    
    CALL CLREG
    
    MOV SI, offset hexAscii
    MOV BX,10
    MOV CX,0
    
    MOV AX,hexIn
    MOV tempHex,AX
    MOV AX,hexIn[2]
    MOV tempHex[2],AX
    
    
    
    H_EXTRACT:
        MOV DX,0
        MOV AX,tempHex
        DIV BX
        MOV tempHex,AX
        
        MOV AX,tempHex[2]
        DIV BX
        MOV tempHex[2],AX
        
        PUSH DX
        INC CX
        
        CMP AX,0
        JNE H_EXTRACT
        
    H_POP:
        POP DX
        ADD DL,48
        MOV [SI],DL
        INC SI
        LOOP H_POP
	    
    RET
        
    
HEXTOASCII ENDP

ADDDOT PROC
    
    CALL CLREG
    
    ; CLEAR asciiDot
    MOV CX,12
    MOV SI,0
    AD_CLASCIIDOT:
        MOV asciiDot[SI],36
        INC SI
        LOOP AD_CLASCIIDOT
    
    CALL CLREG
    
    MOV SI,0
    AD_CHECKHEXASCII:
        MOV AL,hexAscii[SI]
        CMP AX,36
        JE AD_CONTINUE1
        
        INC SI
        JMP AD_CHECKHEXASCII
        
    AD_CONTINUE1:
        ; SI HOLDS THE CHARACTER COUNT
        MOV CX,SI
        INC CX                  ; ADDS SPACE FOR DECIMAL DOT
        MOV BX,CX
        SUB BX,3                ; HOLDS POSITION OF DECIMAL DOT
        CMP BX,0
        JGE AD_CONTINUE11       
        
        MOV BX,0                ; SPECIAL CASE, 0.0x
        
        AD_CONTINUE11:
            MOV SI,0
        AD_TRANSFER:
            CMP SI,BX
            JE AD_DOT
            MOV AL,hexAscii[SI]
            MOV asciiDot[SI],AL    
            INC SI
            LOOP AD_TRANSFER    
        
        AD_DOT:
            MOV DL,hexAscii[SI+1]
            CMP DL,36           ; SPECIAL CASE, 0.0x
            JNE AD_CONTINUE12
            
        ; AD_ZERODOT
            MOV AL,hexAscii[SI]
            CMP AL,48           ; IF 0
            JE AD_ZERODOT0
            MOV DL,46           ; ADD DOT
            MOV asciiDot[SI],DL
            MOV DL,48
            MOV asciiDot[SI+1],DL   ; ADD 0
            INC SI
            MOV asciiDot[SI+1],AL
            JMP AD_CONTINUE2
                                                                    
            AD_ZERODOT0:
                MOV asciiDot[SI],AL ; ADD 0
                JMP AD_CONTINUE2
            
        AD_CONTINUE12:
            
            CMP DL,48           ; COMPARE LAST DIGIT WITH 0
            JNE AD_2D           ; IF NOT 0, THEN IS 2 DECIMAL
            MOV DL,hexAscii[SI]
            CMP DL,48           ; COMPARE 2ND LAST DIGIT WITH 0
            JE AD_CONTINUE2     ; IF IS 0, THEN IS NO DECIMAL
            JNE AD_1D
            
            AD_1D:
                MOV DL,46       ; ADD DOT
                MOV asciiDot[SI],DL
                MOV AL,hexAscii[SI]
                INC SI
                MOV asciiDot[SI],AL 
                JMP AD_CONTINUE2
                
            AD_2D:
                MOV DL,46       ; ADD DOT
                MOV asciiDot[SI],DL
                MOV AL,hexAscii[SI]
                INC SI
                MOV asciiDot[SI],AL
                MOV AL,hexAscii[SI]
                INC SI
                MOV asciiDot[SI],AL
                JMP AD_CONTINUE2       
            
        AD_CONTINUE2:
            CALL CLREG
            
            MOV AL,asciiDot[0]
            CMP AX,46           ; IF DOT IS FIRST CHARACTER
            JNE AD_EXIT
            
            XOR SI,SI
            XOR AX,AX
            AD_CHECKASCIIDOT:
                MOV AL,asciiDot[SI]
                CMP AX,36
                JE AD_CONTINUE4
                
                INC SI
                JMP AD_CHECKASCIIDOT
            
            AD_CONTINUE4:
                
                MOV AL,asciiDot[SI-1]
                MOV asciiDot[SI],AL
                
                CMP SI,1
                JE AD_ZERODOT
                
                DEC SI
                JMP AD_CONTINUE4
            
            AD_ZERODOT:
                XOR AX,AX
                MOV AL,48       ; ADD 0 TO FIRST CHARACTER
                MOV asciiDot[0],48         
                    
        AD_EXIT:    
            CALL CLREG
            RET
            
ADDDOT ENDP


; ========================= OPERATORS ==============================================


power PROC
;====================WELCOME TO THE POWER FUNCTION==============

;--ERROR CHECKING---
cmp ans[0], 0H
JNE pow_error
JE pow_continue

pow_error:
XOR AX,AX
MOV AL,4
MOV errorFlag,AL
JMP  pow_exit

pow_continue:
;PRESETS FOR POWER LOOP

mov ax, num1[0]
mov bx, num1[2]

mov temp_pow[0], ax
mov temp_pow[2], bx

XOR CX, CX
MOV CX, pow_of		;SET LOOP COUNTER TO POWER OF X
SUB CX, 1

BIG_LOOP:
mov pow_counter, cx

;---POWER FORMULA---
POWER_CALC:
                
;===temp power===
mov ax, temp_pow[0]
mov bx, temp_pow[2]

mov num2[0], ax
mov num2[2], bx

call multiply
xor dx,dx
mov dl,errorFlag
cmp dl,0
jne pow_exit

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

;===ROUND OFF 3rd and 4th decimal place===
pow_decimalRound:
mov ax, 0
mov bx, 10000d

mov num2[0], ax
mov num2[2], bx

call division
xor dx,dx
mov dl,errorFlag
cmp dl,0
jne pow_exit

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

;===loop back power===

mov cx, pow_counter

cmp cx, 0
je pow_exit


loop BIG_LOOP


pow_exit:
 
ret 
power ENDP


addition PROC
xor ax, ax
xor bx, bx

mov ax, num1[2]
mov bx, num2[2]
add ax, bx

mov ans+2, ax
mov ax, num1
mov bx, num2
adc ax,bx
jc add_error
mov ans, ax   
   
ret

add_error:
    mov ax,1
    mov errorFlag,al
    
    ret
     
addition ENDP


subtract PROC
xor ax, ax
xor bx, bx
xor dx, dx

mov ax, num1[2]
mov bx, num2[2]
sub ax, bx
mov ans[2], ax

mov ax, num1
mov bx, num2
sbb ax, bx
jc sub_error
mov ans, ax

ret

sub_error:
    mov ax,5
    mov errorFlag,al
    
    ret

subtract ENDP



multiply PROC

xor ax, ax
xor bx, bx
xor cx, cx
xor dx, dx

mov ax, num1[2]
mul num2[2]
mov ans[2], ax
mov cx, dx

mov ax, num1
mul num2[2]
jc mul_error
add cx, ax
jc mul_error
mov bx, dx
jnc mul_move
add bx, 1H

mul_move:
mov ax, num1[2]
mul num2
add cx, ax
jc mul_error
mov ans[0], cx

ret

mul_error:
    mov ax,4
    mov errorFlag,al
    
    ret    
 
multiply ENDP

division PROC
;================  



mov     cx, num2[2]                ;cx = dvsr
xor     dx,dx                  ;dx = 0

;---clear temp_rmdr
mov temp_rmdr, dx

mov     ax, num1[0]    ;ax = high order numerator
div     cx                     ;dx = rem, ax = high order quotient
mov     ans[0], ax   ;store high order quotient
mov     ax, num1[2]      ;ax = low  order numerator
div     cx                     ;dx = rem, ax = low  order quotient
mov     ans[2], ax     ;store low  order quotient
mov     rmdr, dx     ;store remainder

;---CONVERT REMAINDER---
mov si, 0

cmp rmdr, 0
je normal_div       ;changes

div_check:
inc si

mov ax, rmdr
mul tens[0]

jc  cutDiv

conv_dp:
mov ax, rmdr
mul tens[0]

xor dx, dx
mov cx, num2[2]
div cx

mov rmdr, dx

cmp si, 1
je  bxMul

cmp si, 2
je  bxPlus
ja  cx_roundOff      
      
bxMul:
mul tens[0]
mov bx, ax
jmp div_check

bxPlus:
add bx, ax
jmp div_check

cx_roundOff:
cmp ax, 5
jae incBx

mov temp_rmdr, bx
jmp normal_div

incBx:
inc bx
mov temp_rmdr, bx
jmp normal_div      
      
;====
cutDiv:
xor dx, dx
mov ax, num2[2]
div tens[0]

mov num2[2], ax
mov cx, ax

xor dx, dx
mov ax, rmdr
div cx

mov rmdr, dx

cmp si, 1
je bxMul

cmp si, 2
je bxPlus
ja cx_roundOff

;--normal shiz
normal_div:

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

mov ax, 100
mov num2[2], ax

call multiply
xor dx,dx
mov dl,errorFlag
cmp dl,0
jne divExit

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

mov ax, temp_rmdr
mov num2[2], ax

call addition
xor dx,dx
mov dl,errorFlag
cmp dl,0
jne divExit

;---Dividend END POINT OF RECURSION---
cmp di, 0
je dp_checker
pop dx
jmp divExit

;---Decimal Point CHECKING---
dp_checker:         ;CHECK DP (DUH!)
mov ax, word ptr dp
xor ax, 0202h 
                 
cmp ax, 0000h
  jz divExit

cmp ax, 0202h
  je divExit
                                 
cmp ax, 0200h
  je dividend_dec	;Jump if dvidivend has decimal
  jne divisor_dec	;Jump if divisor has decimal


;dividend shiz
dividend_dec:

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

mov ax, 10000d
mov num2[2], ax 

mov di, 1
call division       ;======RECURSION!!!=======
xor dx,dx
mov dl,errorFlag
cmp dl,0
jne divExit

;divisor shiz
divisor_dec:


jmp divExit

divExit:
ret

division ENDP

sqrt PROC

;----CLEAR----
xor ax, ax
xor bx, bx
mov word ptr int32, ax
mov word ptr int32 + 2, ax
mov word ptr squareRoot, ax
mov word ptr squareRoot + 2, ax

;---Initialization for squareRoot---
mov ax, num1[0]
mov bx, num1[2]

mov word ptr int32, bx
mov word ptr int32 + 2, ax

;fild int32        ;load the integer to ST(0)
;fsqrt             ;compute square root and store to ST(0)
;fistp squareRoot  ;store the result in memory (as a 32-bit integer) and pop ST(0)

mov ax, word ptr squareRoot
mov ans[2], ax
mov bx, 0
mov ans[0], bx

;---Fix decimals---
mov ax, ans[2]
mov num1[0], bx
mov num1[2], ax

mov num2[0], bx
mov num2[2], 10d

call multiply

ret
sqrt ENDP


; ================================ OLD CODES ===================================
o_cls proc
    mov ax, 0600h
    xor cx, cx
    mov dx, 184Fh       ;end coord
    mov bh, 3Ah         ;cyan bg, green text
    int 10h    

    ret
o_cls endp

_logo proc ;------------------- PRINT LOGO (1 PAGE) >>> Press any key >>> cls
 
 MOV AH,0
 INT 16H   
 
 CALL o_cls
    
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
 
; MOV AH,0
; INT 16H   
; 
; CALL o_cls   
    
    
    RET
_logo ENDP
; ========================== SPECIAL FUNCTION ======================================== 
clrArg proc 
    push si  
    mov cx, 9
    mov al, "$"
    xor si, si 
    clrV:
        mov Value[si], al
        mov RadianValue[si], al
        inc si
        loop clrV
    
    and ValueSize, 0
    and RadianVSize, 0
    
    call clreg
    pop si
     
    ret  
clrArg endp

sine proc
    ;x/1!-x^3/3!+x^5/5!-x^7/7!+x^9/9!

    xor si, si
    ; convert value to hex
loopConvert:    
    mov al, Value[si]    
    mov asciiIn[si], al
    inc si 
     
    cmp al, "$"
    jne loopConvert
    
    dec si                   
    mov ValueSize, si
    
    ; convert to hex                  
    call ASCIITOHEX
    mov bx, asciiHex[2]

    ; =========================================================     
checkValueRange: 
    ; get value in 180, dx has 180, 90, minimum range   
    cmp bx, 90
    jb noReduce
    
    ; if Value more than 180, decrease within 180 and do again
    mov ax, 90 
    sub bx, ax
    jmp checkValueRange
    
    noReduce:          
        cmp bx, 0
        jz ZeroOP
        ; convert back to string       
        mov hexIn[2], bx
        call HEXTOASCII
        ; result in hexAscii[si]        
         
        ; =========================================================
        ; to Radian 
        xor di, di
        xor si, si
        moveValue: 
            mov bl, hexAscii[di] 
            
            cmp bl, "$"
            je convertV
            
            mov inList[di], bl
            inc di 
             
            jmp moveValue
            ; convert Radian
            convertV:
                mov bl, Radian[si]
                
                cmp bl, "$"
                je outConv 
                
                mov inList[di], bl
                
                inc di
                inc si
                jmp convertV 
    ZeroOP:                
        mov bl, "0"
        mov asciiDot[0], bl
        jmp outSine
            
    outConv:
    
    CALL CLREG
    CALL IN2POST
	CALL POSTOPS
    CALL HEXTOASCII
    CALL ADDDOT 
           
    ; =========================================================
    ; clear asciiDot first and get size
    xor si, si 
    xor cx, cx
    clearASCII:
        ; replace into RadianValue[si]  
        mov bl, asciiDot[si]
        mov al, bl
        mov RadianValue[si], bl
        
        ; clear asciiDot
        mov bl, "$"
        mov asciiDot[si], bl
        
        inc si
        inc cx
        
        cmp al, "$"
        jne clearASCII
        
    ; move Equation
    dec cx
    mov RadianVSize, cl      
    xor si, si  
    xor di, di
moveSine:
    mov bl, SineApprox[di]
               
    ; check for x and replace with the number              
    cmp bl, 'x'   
    jne toInList
    ; --------------------------    
        ; get number from sine button
        xor bx, bx  
        
        ; save di from before     
        push di
        xor di, di
        mov cl, RadianVSize
        getNumbers: 
            mov al, RadianValue[di]
            mov inList[si], al
            inc si
            inc di
            loop getNumbers
            
        ; get next si value in equation
        pop di
        
        inc di    
        jmp moveSine
    ; continue -----------------
    toInList:
    mov inList[si], bl 
    
    inc si
    inc di
    
    cmp bl, "$"
    jne moveSine
    ; =========================================================
    ; convert to ascii
    CALL CLREG
    CALL IN2POST
	CALL POSTOPS
    CALL HEXTOASCII
    CALL ADDDOT
 
    ; result in asciiDot
outSine:
    ret
sine endp

cosine proc
    call sine
    ret   
cosine endp

Trigonometry proc
    ; check for sine
    xor si, si 
    xor di, di
    xor bx, bx
    ; find S until $
    getOP:  
        call clrArg
        mov bl, String[si] 
        mov tempPtr, si
        inc si 
        
        ; get operands
        cmp bl, "S"
        je setOP
        cmp bl, "C"
        je setOP
        cmp bl, "T"
        je setOP  
        ; if end of string out
        cmp bl, "$"
        jne getOP  
        
        ; out
        jmp noOP
    ; ------------------------------- 
        setOP:      
            or directOut, 1
            ; save si value
            push bx
            push si 
            
            loopOP:           
                ; get number after S into Value
                mov bl, String[si]
                
                cmp bl, "_"
                je repZero      
                
                ; check for numbers if no then out 
                sub bl, 30h
                cmp bl, 0
                jl nextVRange  
                nextVRange:
                    cmp bl, 9
                    ja contGet                       
                    
                ; if number then put into value
                add bl, 30h      
                mov Value[di], bl 
                
                inc di
                ; clean value of S
                repZero:
                    mov al, "0"
                    mov String[si], al 
                    
                inc si 
                
                jmp loopOP
        ; replace _ to 0 ------------------  
        ; =========================================================
        ; continue to String[si]
        contGet:
            pop si 
            pop bx
            ; compare operand     
            cmp bl, "S"
            jne next1  
                call Sine
                jmp noOp
 
            next1:
            cmp bl, "C"
            jne next2  
                ; rangeFx in cosine function
                call Cosine
                jmp noOp
            
            next2:
            cmp bl, "T"
            jne next3
                call Sine
                ; move asciidot into inlist and divide 
                call Cosine
                jmp noOp
                
            next3:
                ; call log         
            
            jmp getOP 
        ; =========================================================
        appendStr:
            ;get length of answer
            xor di, di                               
            LEN1:      
                mov al, asciiDot[di]
                inc di
                cmp al, "$"
                jne LEN1
                
            ; pop di into cx and loop
            mov si, tempPtr
            ; append the S before calculation 
            dec si
            mov cx, di
            dec cx
            xor di, di 
            repStr:                               
                ;get asciiDot and write into String
                mov bl, asciiDot[di]                 
                ;mov String[si], bl
                
                inc di
                inc si
                
                loop repStr
                 
                jmp getOP             
        
 noOP: 
    and tempPtr, 0
    ret
Trigonometry endp     
; ================================= UI ===========================================================

; TINY FUNCTIONS ==============================================
sleep proc
    ; set 1 million microseconds interval (1 second)
    ;mov cx, 0fh        
    ;mov dx, 4240h 
; modified count ------------------------- SET TIMER HERE
    mov cx, 2h          ; high order word  
    mov dx, 2h          ; low word
    mov ah, 86h
    int 15h
    ret

print proc
    mov ah, 9
    int 21h
    xor dx, dx
    ret       

Throw proc
    lea dx, err
    call print
    or errBool, 1
    
    ret    

cursor proc
    mov ah, 2          
    mov bh, 0
    int 10h
    ret
    
cls proc
    mov ax, 0600h 
    xor cx, cx
    mov dx, 184Fh
    mov bh, 07h
    int 10h 
    ret
        
bgcolor proc
    mov ax, 0600h
    int 10h
    ret 
    
clrEntry proc  
    ;clear top calculator  
    call cls
    
    xor ax, ax
    xor bx, bx
    xor cx, cx 
    call clstr              
               
    xor dx, dx
    call cursor
    
    lea dx, ScreenUI       
    call print
    
    ;Color Boxes
    mov cx, 0702h               ; Rows : Col
    mov dx, 144Bh               ; end row col    154Bh
    mov bh, 7Fh                 ; grey : White font    
    call bgcolor                
 
    xor cx, cx 
    mov dx, 0700h               ; display buttons   
    call cursor
    
    lea dx, scanf    
    call print  
    
    mov dh, String_y            ; constant row
    mov dl, String_x            ; constant column 
    
    mov Update_Col, dl          ; reset    
       
    call cursor 
    
    xor si, si  
    xor di, di   
    
    mov ah, 2
    mov dl, 30h    
    int 21h          
 
    ; clear input buffer       
    mov inPtr, si
    mov StringPtr, si
                
    and tPtr, 0
    and DigitF, 0
    
    and opF, 0
    inc opF
          
    ret   
    
clstr proc     
    mov al, "$"
    mov cx, 70       
    xor di, di
t:     
    mov tempStr[di], al
    mov String[di], al
    inc di
    jcxz out_t    
    loop t   
out_t:     
    ret            
 
; Mouse Cursor function ==================================================
_Cursor proc              
    ;disable blink
    mov ax, 1003h   
    xor bx, bx
    int 10h
 
    ; hide text cursor   
    mov ch, 32
    mov ah, 1
    int 10h   
    
    mov dx, 0647h
    call cursor    
    lea dx, str1
    call print  
    
    mov ax, 1                 ; show cursor
    int 33h                   
    
    mov Mode, al              ; mode = 1, mouse mode 
    
    mov ax, 3                 ; get buttons
    int 33h   
    
    test bl,1                 ; AND bits with 0000 0001
    jnz left_button       
    test bl,2                 ; AND bits with 0000 0010        
    jnz right_button  
     
    xor ax, ax                ; clear avoid loop    
    jmp no_button  
    
left_button:  
    mov ax, dx                          ; ax has row coord
    mov bx, cx                          ; bx has col coord  

    xor cx, cx
    xor dx, dx 
    xor si, si
           
    mov cl, start_Row                   ; upper row      3F19h
    mov dl, end_Row                     ; lower row                            
Outer_Loop:    
    push cx                             ; save upper row coord
    push dx                             ; save lower row coord  
    
    cmp ax, cx                          ; compare if it's in current row 
    jb break_1             
    cmp ax, dx
    ja break_1       
    
    mov cx, start_Col                   ; upper Col
    mov dx, end_Col                     ; lower Col
    
    Inner_Loop:                                              
        cmp bx, cx                      ; Upper Col: bl < cl then out
        jb break_2
        cmp bx, dx                      ; Lower Col: bl > dl then out
        ja break_2   
        
        jmp operation                   ; tested is within the box then do
    break_2:                            ; skip to right cell    
        add si, 2                       ; next array_byte cell

        add cx, 50h                     ; to right box 
        add dx, 50h
        cmp dx, 01F7h                   ; compare lower column to maximum width
        jne Inner_Loop      
break_1:      
    pop dx
    pop cx
    
    add si, 10                          ; for array_byte location       
    
    add cx, 0010h                       ; upper row to next row
    add dx, 0010h                       ; lower row to next row
    
    cmp dx, 00B7h                       ; compare lower row to maximum depth
    jne Outer_Loop 
    
    xor ax, ax
    jmp no_button                       ; no button scanned then out
    
operation:  
    pop dx                              ; avoid stack having previous values
    pop dx                              ; clear, This     
    mov ax, array_button[si]   
       
    cmp ax, array_button[8]             ; Switch mode
    jne no_button                       ; if ax = "m", no jump
right_button:                          
    mov ax, array_button[8]
    call _KeyPress             
    dec Mode                            ; Mode = 0, Keyboard mode  
    
    mov ax, 2                           ; hide cursor 
    int 33h    
    
    xor ax, ax      
no_button:   
    mov upperIn, ah                     ; clear both avoid auto assign 
    mov Input, al  
    
    ret
_Cursor endp  
;=================================================================================
_Calculator proc                              
    call clrEntry               
    
;OPERATION STARTS HERE
L1:          
    xor cx, cx 
    mov dx, 0700h               
    call cursor
    
    ; Scan from file display
    lea dx, scanf    
    call print
 
    ; cursor input
    test Mode, 1                ; if 1 then switch to Mouse                    
    jnz MOUSE
    
    mov dx, 0647h
    call cursor
    lea dx, str0
    call print        
                   
    ; all keys accepted     
    mov ah, 0                   ; no blink cursor
    int 16h                     ; int 16h stores the complete arrow key hexa code into AX                  
   
    mov upperIn, ah             ; special input stored in AH
    mov input, al       
            
L2:                           
    cmp ax, 0                   ; for mouse key to avoid key press
    jz L1              
    
    ; key animation   
    call _KeyPress   
    
    test Bool, 1                ; if 1 then true else no
    jz L1         
    
    mov ah, upperIn
    mov al, input 
    
    ; Enter button 
    cmp ax, array_button[68]
    je ENTERED
                 
    cmp ax, array_button[8]
    je MOUSE   
    
    cmp ax, array_button[6]
    je EXT                                   
    
    ; Clear Entry to reset position
    cmp ax, array_button[22]     
    je CL_ENTRY           
    
    cmp ax, array_button[26]
    je BSPC
    
    cmp ax, array_button[18]
    ;je Records
    cmp ax, array_button[24]
    je Graph
    
    ; maximum size of 30 
    mov si, inPtr                       ;StringPtr
    cmp si, inLimit     
    jge L1         
    mov di, StringPtr
    cmp di, 101
    jge L1        
                 
    call _DetectKeys    
              
    jmp L1
; Jump to function
MOUSE:                                  
    call _Cursor
    mov ah, upperIn
    mov al, input
       
    jmp L2
    
ENTERED:        
    cmp inPtr, 0
    jz noEnter

    and input, 0
    CALL UIMERGE
    
noEnter:
    jmp L1    
    
CL_ENTRY:
    call clrEntry 
    jmp L1

BSPC:
    call _BackSpace 
    jmp L1
       
Graph:
    call _Setup
    jmp L1      
                                
EXT:      
    mov ax, 2
    int 33h
    ret   
_Calculator endp    
   
; FUNCTIONS ===================================================
Math_Operators proc
    mov al, input
    mov ah, upperIn 
    ;----------------------------------------------------------------------    
    cmp ax, array_button[0]
    jne nextButton1
      
    mov al, 253                             ; al = ascii ^2
       
    jmp ByteKeys                                                      
    
    ;----------------------------------------------------------------------
nextButton1:    
    ;cmp ax, array_button[4]                     ; HAS NO KEY YET
    jne nextButton2
    
    ; Log
nextButton2:      
    cmp ax, array_button[10]
    je checkBrac   
    
    jmp nextButton3                             ; jump issues
    
    checkBrac:                 
        mov si, inPtr 
        xor bx, bx 
        mov cx, 1
        xor di, di       
                                                                      
        mov bl, tempStr[si-1]                    ; check byte before
        cmp bl, ')'                              ; if is bracket do bracket loop
        je bracLoop 
         
        isDigit: 
            cmp si, 0
            jz addSI
                   
            dec si  
                        
            mov bl, tempStr[si]
            mov tempStr[si+1], bl               
                                                 
            ; if isDigit 
            sub bl, 30h
            cmp bl, 0
            jge nextRange                       ; stopped here not jump for not number
            
            nextRange:
                cmp bl, 9
                jbe isDigit        
                
            loop isDigit
             
            addSI:
            inc si 
            jmp noRep
        ; -------------------------------     
        bracLoop:
            cmp si, 0
            jz noRep
                 
            dec si  
            
            mov bl, tempStr[si]
            mov tempStr[si+1], bl 
            
            cmp bl, ')'
            jne bracCount
            
            inc di
            
            bracCount:            
                cmp bl, '('
                jne bracLoop

                dec di
                
                cmp di, 0
                jnz bracLoop
                                                                   
            loop bracLoop 
            ;dec si                                                                                                                                                                  
    noRep:         
        mov al, 251                              ; add from above
    
        jmp ByteKeys
    ;----------------------------------------------------------------------
nextButton3: 
    cmp ax, array_button[12]               
    jne nextButton4
    
    ;print SIN( for tempStr
    mov si, inPtr
    mov al, "S"
    mov tempStr[si], al
    mov al, "I"
    mov tempStr[si+1], al
    mov al, "N"
    mov tempStr[si+2], al
    mov al, "_"
    mov tempStr[si+3], al
    add si, 4
    ; update pointers
    mov inPtr, si 
    dec si  
    mov ax, si
    sub Update_Col, al 
    
    ; write S180 in String for sine
    mov si, StringPtr         
    ;input = S
    mov bl, input
    mov String[si], bl 
    mov bl, "_"
    mov String[si+1], bl
    mov String[si+2], bl
    mov String[si+3], bl            ; remove these later 
    mov String[si+4], bl
    inc StringPtr                              
                
    jmp NOKEYREG   
    ; Sine 
nextButton4: 
    cmp ax, array_button[14]
    jne nextButton5 
    
    ; Cosine
nextButton5:    
    cmp ax, array_button[16]
    jne nextButton6

    ; Tangent
nextButton6:                             
    cmp ax, array_button[20]
    jne nextButton7
    
    mov si, inPtr   
    mov di, StringPtr
    mov cx, 2 
    
    xor bx, bx              
    isDigit2:                               ; check for operand
        mov bl, tempStr[si-1]                        
        mov bl, String[di-1]    
                
        mov tempStr[si+1], bl               ; tempStr[si+2] = tempStr[si]
        mov String[di+1], bl
          
        cmp si, 0                           ; if inPtr is 1-- = 0 then out
        je noRep2                               
        
        jcxz noRep2
                                        
        dec si                              ; update index
        dec di   
                                                                    
        ; if isDigit 
        sub bl, 30h
        cmp bl, 0
        jge nextRange2
        
        nextRange2:
            cmp bl, 9
            jbe isDigit2  
        
        loop isDigit2
noRep2:                  
    mov bl, "1"
    mov tempStr[si], bl
    mov String[di], bl
    
    mov bl, "/"
    mov tempStr[si+1], bl
    mov String[di+1], bl
    
    mov bx, 2
    add inPtr, bx
    add StringPtr, bx
    
    dec Update_Col

    jmp NOKEYREG
    
nextButton7:                                ; 2.718
    cmp ax, array_button[30]
    jne nextButton8
    
    mov si, inPtr
    mov tempStr[si], al
    inc inPtr
    
    mov di, StringPtr 
    xor si, si
    wrExp:
        mov al, e[si]
        mov String[di], al
        inc StringPtr
        
        inc di
        inc si        
        cmp si, 4
        jne wrExp
        
    jmp NOKEYREG 
    
nextButton8:   
    cmp ax, array_button[40]                ; 3.14
    jne nextButton9
    
    mov si, inPtr
    mov al, 227
    mov tempStr[si], al
    inc inPtr
    
    mov di, StringPtr 
    xor si, si
    wrPi:
        mov al, pi[si]
        mov String[di], al
        inc StringPtr
        
        inc di
        inc si        
        cmp si, 4
        jne wrPi
        
    jmp NOKEYREG

nextButton9:    
    ;jmp ByteKeys         
    
    ;----------------------------------------------------------------------
    ; No key match above only go bytekeys label
    mov al, Input                        
    mov si, inPtr 
ByteKeys:                           ; print for display                
    mov tempStr[si], al             ; write into temp string    
    inc inPtr                                            
    
    ; Only for String keys, if no match button above only jump to ByteKeys
    mov al, Input    
    mov di, StringPtr      
    mov String[di], al
    inc StringPtr                     
   
NOKEYREG:
    xor di, di
    xor si, si
    
    and input, 0
    and upperIn, 0
    
    ret
Math_Operators endp 
;----------------------------------------------------------------
_DetectKeys proc
    ; This function get keys from keyboard to temporarily save into var
    xor ax, ax                   
    mov al, input                   ; this AL input print without AH value    

    call _Constraint
    
    call Math_Operators           ; separated function for all +-*/ 
    
    mov dh, String_y                ; row 4
    mov dl, Update_Col              ; column -1 each keys 
    call cursor          
    
    ;update column               
    dec Update_Col           
                                       
    lea dx, tempStr                 ; display a byte
    call print    
    
OP_END:   
    ret   
_DetectKeys endp    
;----------------------------------------------------------------

;----------------------------------------------------------------
_BackSpace proc
    cmp inPtr, 0                    ; avoid si turn FF FF
    jne HAS_BSPC
    jmp NO_BSPC                     ; jump out of range

HAS_BSPC:    
    mov si, inPtr                   
    mov di, StringPtr 
    
    mov al, "$"             
    mov tempStr[si-1], al           ; replace current with $
    dec inPtr                       ; for string position 
             
    mov String[di-1], al            ; replace current with $
    dec StringPtr   
                      
    xor dx, dx
    call cursor   
    lea dx, ScreenUI       
    call print 
    
    inc Update_Col
    
    mov dh, String_y                ; row 4
    mov dl, Update_Col              ; to pointed column after increment
    call cursor         
     
    lea dx, tempStr                 ; display remaining string
    call print  
    
    ;mov si, inPtr
    mov si, StringPtr 
    ;-----------------------------------------
    ;mov al, tempStr[si-1]
    mov al, String[si-1] 
    
    cmp al, "s"
    je DECPTR
    cmp al, "q"
    je DECPTR
    cmp al, "e"
    je DECPTR
    cmp al, "p"
    je DECPTR
    cmp al, "I"
    je DECPTR 
    cmp al, "S"
    je DECPTR
    cmp al, "C"
    je DECPTR                                    
    cmp al, "T"
    je DECPTR
    cmp al, "."              
    je DECPTR    
    cmp al, "("
    je NOTNUM
    cmp al, ")"
    je SETF
    cmp al, "!"
    je DECPTR        
    
    sub al, 30h    
    cmp al, 0
    jl NOTNUM                  
    jz INNERBRAC                ; if 0 skip check tPtr
    cmp al, 9
    jg NOTNUM                   ; to filter search only numbers 
    
    cmp StringPtr, 0
    ja SETF
      
    ; if pointer > 0, set flag, decrease tPtr
    cmp tPtr, 0
    ja SETF
        
    NOTNUM:           
        ; else no set and exit, tPtr == 0
        mov al, 1
        mov opF, al
        
        SETDF:             
            and DigitF, 0       
            jmp OUTC2                                 
            
        DECPTR:
            dec tPtr
            jmp SETDF
             
            INNERBRAC:                      ; if (0. then set digitF, 0
                mov bl, "("
                cmp bl, String[si-2]       ; else it is 10, 100, 1000 ..
                je SETDF                        
SETF:           
    or DigitF, 1     
    dec tPtr      
    cmp si, 1
    jz SETDF                                 
OUTC2:     
    ;-----------------------------------------   
    cmp inPtr, 0                    
    jne NO_BSPC
             
    mov ah, 2
    mov dl, 30h    
    int 21h 
    
    and DigitF, 0         
NO_BSPC:          
    ret
_BackSpace endp    
;----------------------------------------------------------------
_KeyPress proc
    ; This function will toggle any keys pressed directly        
    mov dl, 1                       ; combined constaint checking
    mov Bool, dl       
      
    xor bx, bx                      ; Row update
    xor si, si                      ; loop until 35
    mov ch, 07h                     ; Row top
    mov dh, 08h                    
OUT_L:                              ; decrease for 1 row
    mov di, 0                       ; Column update                   
    mov cl, 02h                     ; Column left
    mov dl, 0Ch                    
    
    IN_L:                               ; decrease for 5 column  
        cmp ax, array_button[si]        ; starting from bottom right 35 total
        je TOGGLE_BUTTON                 
        
        add cx, Col
        add dx, Col
        
        inc di                          ; -1 col   
        add si, 2                       ; array count down
        
        cmp di, 5                       ; Column 5 total
        jne IN_L           
    
    add cx, Row
    add dx, Row      
    
    inc bl                          ; -1 row   
    cmp bl, 7                       ; Row 7 total
    jne OUT_L      
    
    xor dx, dx                      ; keys not match with calculator
    mov Bool, dl                    ; 1 = true, 0 = false

    jmp NOT_BUTTON         
    
TOGGLE_BUTTON:                      ; End Key will be selected 
    call _onPress      
    
NOT_BUTTON:                
    ret     
    
_KeyPress endp 
; -------------------------------------------------------------------------------
_onPress proc                
    mov bh, 0Bh         ; black color, background color overlaps font   <----- customize color 
    call bgcolor               
    
    push cx             ; save cx and dx
    push dx             

    ; set cursor so that it doesn't scroll the screen down
    mov dx, 0700h
    call cursor    
    lea dx, scanf
    call print        
    
    call sleep   
    
    pop dx             
    pop cx
        
    mov bh, 7Fh
    call bgcolor 
    
    ret     
_onPress endp   
;----------------------------------------------------------------
_Constraint proc
    ; term == 0, accept all keys, if AL != 0 then for all set flag                                
    ; if AL == 1 ~ 9
    cmp al, "s"
    je NOTZ
    cmp al, "q"
    je NOTZ
    cmp al, "e"
    je NOTZ
    cmp al, "p"
    je NOTZ
    cmp al, "I"
    je NOTZ 
    cmp al, "S"
    je NOTZ
    cmp al, "C"
    je NOTZ
    cmp al, "T"
    je NOTZ
    cmp al, "."
    je NOTZ
    cmp al, "("
    je NOINC
    cmp al, ")"
    je NOFLAG
    cmp al, "!"
    je NOTZ    
            
    sub al, 30h                 ; al < 0 skip flag
    cmp al, 0
    jb NOTINT
    cmp al, 9                   ; al > 9 skip flag
    ja NOTINT                             
                
        ; if digitF = 1: skip bottom one                                                       
        cmp DigitF, 1                   ; 10000 is valid until user press + - ...
        je SAVEVAR                    ; DigitF : 0 = new term, 1 = continuous number

        ; if term >= 1
        cmp tPtr, 1
        jb PTRZERO                 
            ; if number before AL != 0
            ;cmp tempStr[si-1], "0"
            cmp String[si-1], "0"
            jne NOTZ
            
            inc Update_Col          ; call cursor
            dec tPtr                ; tPtr--  
            dec inPtr               ; inPtr = 0
            dec StringPtr                       
            
                ; if AL == 0 
                cmp al, 0
                jnz NOTZ  
                    
                and DigitF, 0
                
                jmp SAVEVAR 
        ; term == 0     
        PTRZERO:   
            cmp al, 0
            jz SAVEVAR
                   
        NOTZ:                                                                  
            or DigitF, 1                ; set flag                                               
    SAVEVAR:
        inc tPtr 
        
    NOINC:
        and opF, 0            ; no spam operand more than 1       
                             
    jmp OUTC                   
; if AL is an operand, reset term and pointer                                                   
NOTINT:                                      
    cmp opF, 0
    jz NOPOPDX
    
    pop dx                      ; pop return address, exit backspace
    jmp OUTC
    
    NOPOPDX:
        mov al, 1
        mov opF, al              ; opF will turn 1 after 
    
NOFLAG:         
    and DigitF, 0               ; operand detected set term to 0 
    and tPtr, 0                 ; set to 0
    and opF, 1                  
         
OUTC:      
    ret    
_Constraint endp
;----------------------------------------------------------------
_Calc_UI proc
    mov ah, 3Dh         ;Read
    mov al, 0
    lea dx, Testing
    int 21h
    
    mov handle, ax
    
    mov ah, 3Fh   
    mov bx, handle
    mov cx, ScanLength  
    lea dx, scanf
    int 21h         
    
    mov ah, 3Eh
    mov bx, handle
    int 21h 
    
    ret
_Calc_UI endp 
;START GRAPH =================================================================
_Setup proc
Fx_In: 
    call _clearVar
       
    push es
                  
    out 0F3h, ax                 
    mov ax, 0A000h
    mov es, ax
    
    mov ax, 13h    
    int 10h    
    
    call _Equation 
    
    cmp errBool, 1
    je Halt
    
    call _Graph
    
    ;mov ax, 4F02h           ; SUPER VGA MODE
    ;mov bx, 0107h           ; bigger resolution
    ;int 10h
    
    ;call _Axis              ; color works well on emu8086 but not dosbox..      

Halt:    
    pop es     
 
    lea dx, Cont
    call print
    
    mov ah, 1
    int 21h     
    
    cmp al, 'q'
    je outFx
                            
    jmp Fx_In    
    
outFx:       
    mov ax, 3       ; return to text mode
    int 10h         ; auto cls
    
    ret  
_Setup endp
 
_Graph proc
    call _Adjustment    
 
    mov ax, -2               ; double the x range and auto fix sign
    imul x
    mov x_axis, ax  
    xor dx, dx               ; clear sign 
    
    cmp x_axis, 0
    jge Pos_Range 
    
    neg x_axis
    mov bx, 0  
    mov x, bx                ; set x to 0
                          
Pos_Range:
    
    call _Pixel             ; Remove this when ready
    ;------------------------------------------------    
    xor si, si
    mov cx, x_axis
plot_graph:                                 
    push cx                 ; save counter 
;============================================================================                                                         
    call _Parameter         ; set x and y coordinates     
    
    xor cx, cx
    cmp xFlag, 0            ; exponential function
    jz Exponential
    
    cmp ExpSign, -1
    jle Inverse              ; previous is jle, test for js
    
    call _Function      ; function types here
    
    jmp print_pixel        ; jump to end
    
Inverse:
    call _Inverse  
    jmp print_pixel 
    
Exponential:
    call _Exponential
       
print_pixel:   
    call _Pixel             ; draw pixels, place this to line before pop cx                                  
;=============================================================================
    pop cx                      ; update counter here 
    loop plot_graph        
    
    ret
_Graph endp
;=============================================================================

_Pixel proc                        
    ; graph doesnt go out of screen resolution
    ; remove these to get more accurate graph    
    cmp scr_y, 200
    ja no_pixel
    cmp scr_x, 320
    ja no_pixel 
    ;negScr:                    ; for X^-6, -7...
    ;cmp scr_y, -200
    ;jl no_pixel
    ;cmp scr_x, -320
    ;jl no_pixel     
    ; formula for this: y * 320 + x                  
    mov bx, scr_y
    mov ax, Def_size             
    mul bx     
    add ax, scr_x
    push ax
    
    xor ax, ax
    xor bx, bx 
    xor cx, cx
    xor dx, dx
    
    ; color the pixels       
    cld         
    mov al, color
    mov cl, 1  
    mov dl, 7 
    pop di
    rep stosb 
no_pixel:
    ;inc color                  ; changes color 
    ret  
_Pixel endp
;===================================================================================
_Function proc 
    mov ax, pow_x               ; here starts y operation                         
    cwd                         ; if number too big cwd will become signed, so place here
        
    cmp exp, 1                  ; if x^n, n <= 1 then skip any multiplier
    jle linear                  
     
    mov cx, exp                 ; move exp for loop
    dec cx 
    
PowerFX:                          ; exponential function 
    mul pow_x  
    jo linear                   ; jump overflow
    loop PowerFX 
     
linear:       
    cmp x, 0                    ; if x is more than 0, then sub
    jg Positive    
    
    mov cx, exp
    test cx, 1
    jz Positive                 ; jump if even function, x^2,4,6, since square always positive
      
Negative:                       ; no sign involve             
    div times                   ; ax=-3 now ax=3 so add
    mul gradient
    mul gradient_sign
    add scr_y, ax
       
    jmp exit_graph     
Positive:    
    div times                   ; error here 1/3 is 0 integer 
    mul gradient
    mul gradient_sign               
    sub scr_y, ax                                              
          
exit_graph: 
    ret           
_Function endp 
;===================================================================================
_Inverse proc                                              
    mov ax, Inv_x
    cwd 
    
    cmp x, 0  
    jz exit_Inv_graph
    jg Inv_Positive
    
    mov cx, exp
    test cx, 1
    jz Inv_Positive
 
    mul times   
    div pow_x                    ; Negative
    mul gradient
    mul gradient_sign   
    add scr_y, ax
                  
    jmp exit_Inv_graph            
Inv_Positive: 
    mul times        
    div pow_x                    ; Positive
    mul gradient
    mul gradient_sign
    sub scr_y, ax 

exit_Inv_graph:
    ret
_Inverse endp
;===================================================================================
_Exponential proc  
    ;dec scr_x                  ; enable this????????????????????????????????        
    ; for negative exp case reverse Exp_Pos with Exp_Neg process ****************<<<<
    push ax               
    xor dx, dx
    mov ax, pow_x               ; set x as exp, n^x                    
    mul exp                     ; a^(nx)
    div expDiv                  ; for a^(x/n)
    mov cx, ax                  ; set for loop
    pop ax                                                                                     
    
    push iBase                  ; set 'iBase' to 'base'
    pop base                                      
                                                       
    cmp iBase, 0                ; checks if Z+ base is negative
    jge skip_base
    
    neg base                    ; if base is negative, negate   -a*n
    neg baseSign                ; separate sign from 'base'     -a = base gradient
    
skip_base:        
    mov ax, base                ; get positive pow
    cwd      
      
    and ax, ax 
    jz Exp_Pow                  ; x must be positive for base 0                        
    
    push ax
    mov ax, x
    mul ExpSign
    mov bx, ax
    pop ax
    
    ;cmp x, 0                    ; check old file in drive to revert
    cmp bx, 0
    jg Exp_Pow       
    
    cwd    
; if x less than 0 --------------------------------------------------          
Exp_Div:   
    div base                             ; division result always close to 0, x^-n
    xor dx, dx                          ;clear R
    jz base_sign           
    
    jcxz base_sign        
    loop Exp_Div                       ; this do with cx and loop 
             
    jmp base_sign       
    
; if x more than 0 --------------------------------------------------   
Exp_Pow:      
    mul base 
    jo baseOF
    jcxz outPow  
    loop Exp_Pow
    
    jmp outPow
baseOF:
    div base
      
outPow:           
    mov bx, x
    dec bx            
    cmp base, bx
    jne base_sign 
    mov ax, 1              
    
base_sign:
    cmp iBase, 0
    jl Exp_Negative             ; negative exp
    
Exp_Positive:                   ; positive exp  
    mul gradient
    div times                   
    mul gradient_sign
    mul baseSign      
    sub scr_y, ax    
    
    jmp exit_exp      
    
Exp_Negative:                   
    mul gradient
    div times                   
    mul gradient_sign           ; divide overflow
    mul baseSign        
    add scr_y, ax               ; go down

exit_exp:  
    ret       
_Exponential endp 
;===================================================================================
_Adjustment proc     
    cmp xFlag, 0
    jnz set_range            ; NOT EQUAL 
; -------------------------------------------------------------------------
    mov ax, gradient
    mov bx, times
    div bx      
    cmp ax, 10
    jl noSetTimes   
    
    add ax, ax              
    mov times, ax
    
    mov ax, exp
    mov bx, expDiv
    div bx
    
    cmp ax, 10
    jl noSetTimes
    
    add ax, ax
    mov times, ax
    
    noSetTimes:    
        cmp iBase, -1            ; if base is 1 or -1 then times can be 1
        je skip_exp_set 
        cmp iBase, 1             ; if base is 1 or -1 then times can be 1
        je skip_exp_set              
        cmp iBase, 0        
        jz abs_x                 ; base = 0        
        
        cmp times, 9             ; times >= 2
        ja skip_exp_set                
        mov times, 10            ; set at least 10, divide overflow  
        
        mov bx, 20               ; x+20 extend graph
        add x, bx
        jmp skip_exp_set  
    
    abs_x:   
        neg x      
        sub x, 10
    
skip_exp_set:    
    jmp exit_set
; -------------------------------------------------------------------------
set_range:     
    mov cx, exp
    cmp cx, 3               ; both -3 and 3 
    jb exit_set 
    
    sub cx, 3   
    mov si, cx   
                                                                  
    mov ax, 10               ; x starts at negative
    mov bx, ax              ; ax = bx                 
    
    mov cx, exp  
    sub cx, 2                                                 
mul_loop:                   ; x^3 = 10, x^4 = 100 x^5 = 1000
    mul bx
    jc stop_mul             ; this doesnt calculate minimum 'times' value for divide
    dec si  
    cmp si, 0
    loop mul_loop   

stop_mul:   
    div bx
    and bx, bx                   ; clear sign flag                                          
    cmp ax, times                ; times has to be atleast x10 of x
    jle exit_set                 ; before was jbe, has sign flag 
                 
    ; else set times at least 100
    mov ax, x                ; minimum times value * 10
    neg ax 
    cwd                      ; just to make sure, exp can go above 35
    
    div bx                   ; test<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  
    
    mov cx, exp 
    sub cx, 2
loop_times:   
    mul bx                   ; bx = 0Ah from above
    jc stop_loop                         
    loop loop_times 
                                          
stop_loop:  
    add x, bx                ; reduce bx by 10 <<<<<<<<<<<<<<<<<, remove if no use
    
    div bx
    xor dx, dx               ; lower ax into times 
    mov times, ax 
; -------------------------------------------------------------------------                  
exit_set:                              
    ret
_Adjustment endp    
;===================================================================================
_Parameter proc               ; this function sets x and y and neg signed values
    ; x variable -----------------------------------------
    push coordxy[0]         
    pop scr_x                   ; set x screen coordinate 
   
    mov bx, x                   ; bx=-20 
    and bx, bx                  ; set sign flag
    add scr_x, bx               ; 160-20   
    inc x                       ; x starts from -20 to positive 20  
    inc scr_x
   
    ; y variable ----------------------------------------- 
    push coordxy[2]        
    pop scr_y                   ; put y for screen position   
    
    push x
    pop pow_x                   ; set pow_x from x
    
    cmp x, 0
    jge skip_neg                ; if x is negative then negate pow_x, avoid div overflow
  
    neg pow_x                   ; no overflow cause         
skip_neg:                                                         
    ret
_Parameter endp 
;===================================================================================
;_Parameter_Y proc
;    ; y variable --------------------------------------------------
;    push coordxy[2]         
;    pop scr_y                   ; set x screen coordinate 
;   
;    mov bx, y                   ; bx=-20 
;    and bx, bx                  ; set sign flag
;    add scr_y, bx               ; 160-20   
;    inc y                       ; y starts from -20 to positive 20  
;    inc scr_y
;   
;    ; x variable ----------------------------------------- 
;    push coordxy[0]        
;    pop scr_x                   ; put y for screen position   
;    
;    push y
;    pop pow_y                   ; set pow_y from y
;    
;    cmp y, 0
;    jge skip_neg_1                ; if y is negative then negate pow_y, avoid div overflow
;  
;    neg pow_y                   ; no overflow cause  
;skip_neg_1:   
;    ret
;_Parameter_Y endp
;===================================================================================
_Equation proc             
    mov ah, 2
    mov dl, "Y"
    int 21h 
    
    mov ah, 2
    mov dl, "="
    int 21h
    
    mov ah, 0Ah
    lea dx, ARRAY
    int 21h     
                
    xor si, si   
    xor di, di            
    mov bl, Formula[si]
    
    call _clearAscii 
    
    cmp bl, '-'
    jne noNegGradient
    
    neg gradient_sign
    inc si  
        
    noNegGradient: 
        mov bl, Formula[si]         ; si++
        
        ; next 1st exit
        cmp bl, 'X'
        je LinearFx
        
        ; next 2nd exit
        cmp bl, '('
        je ExpBase
        
        call getNumber
        
        jmp noNegGradient  
        
        ExpBase: 
            ; checks if input is (X)
            inc si
            mov bl, Formula[si]
            cmp bl, 'X'
            je LinearFx
            dec si
            
            jmp ExpFx    
        ; ====================================================           
        ; Normal Graph =======================================
        LinearFx:     
            ; xFlag 1 = Linear graph
            or xFlag, 1 
 
            push si           
            call ASCIITOHEX
            pop si
                   
            mov ax, asciiHex[2]
            mov gradient, ax 
            
            inc si
            
            ; if formula[si] == ^
            mov bl, Formula[si]         ; si++
            cmp bl, '^'
            je hasExp
            
            ; else set exp == 1
            mov ax, 1
            mov exp, ax 
 
            ; end checking           
            ; cmp bl, 0Dh 
            
            ; end formula without exp
            jmp outE        
            ; ====================================================
            hasExp:  
                inc si
                ; check for (
                mov bl, Formula[si]
                cmp bl, '('
                je noErr
                
                call Throw
                jmp outE
                
            noErr:
                inc si
                ; check for exp sign
                mov bl, Formula[si]
                cmp bl, '-'
                jne noNegExp
                
                neg ExpSign
                
                inc si  
                                            
                noNegExp:
                    ;else proceed to find for expdiv
                    ;inc si 
                    call _clearAscii
                addExp1:    
                    ; checks only for whole number, fraction not supported
                    mov bl, Formula[si]
                    
                    call getNumber   
                    
                    ; ends with ) end exp for normal graph
                    mov bl, Formula[si]
                    cmp bl, ')'
                    je endExp
                    
                    jmp addExp1   
        ; ========================================================                                   
        endExp:            
            ; convert ExpDiv for normal graph 
            push si
            call ASCIITOHEX
            pop si
            
            mov ax, asciiHex[2]
            mov exp, ax 
            
            inc si 
            
            ; check if has / next           
            mov bl, Formula[si]
            cmp bl, '/'
            jne endFx
            
            ; do division
            jmp DivFx            
            ;else end           
            endFx:
                jmp outE
 ;=================================================================                   
        ; Exp Function ==============================================     
        ExpFx:              
            ; xFlag 0 = Exp
            and xFlag, 0                
                       
            push si                      
            call ASCIITOHEX
            pop si  
            
            ;set for gradient       
            mov ax, asciiHex[2]
            mov gradient, ax
            
            inc si        
            
            ; check for base sign
            mov bl, Formula[si]
            cmp bl, '-'
            jne noNegBase
            
            neg BaseSign
            
            inc si    
            
            noNegBase: 
                ;inc si
                call _clearAscii
            addBase:
                ;check for iBase
                mov bl, Formula[si] 
                
                call getNumber 
                
                ; after assigning number find if )
                mov bl, Formula[si]         ; si++
                
                ; find next is )
                cmp bl, ')'
                je setBase
                
                jmp addBase
                ; =================================================== 
                setBase:
                    ; set iBase 
                    push si
                    call ASCIITOHEX
                    pop si
                           
                    mov ax, asciiHex[2]
                    mov iBase, ax 
                    
                    inc si
                    
                    ;next must end with ^
                    mov bl, Formula[si]         ; si++
                    cmp bl, '^'
                    jne err4

                    inc si
                    ; check for (
                    mov bl, Formula[si]
                    cmp bl, '('
                    je noErr2
                    
                    call Throw
                    jmp outE
                    
                noErr2:
                    inc si
                    ; check for exp sign
                    mov bl, Formula[si]
                    cmp bl, '-'
                    jne noNegExp2
                    
                    neg ExpSign
                    
                    inc si  
                         
                    noNegExp2:
                        ;else proceed to find for expdiv
                        ;inc si
                        call _clearAscii 
                    addExp2:
                        mov bl, Formula[si]
                        
                        ; if next is not number then jmp to error
                        cmp bl, 'X'
                        je setExp
                        
                        call getNumber   
                        
                        jmp addExp2
                        ; ==============================================
                        setExp:       
                            push si
                            call ASCIITOHEX
                            pop si
                            
                            ; set exp gradient
                            mov ax, asciiHex[2]
                            mov exp, ax
                        
                            inc si
                            
                            ; inner bracket divide
                            mov bl, Formula[si]
                            cmp bl, '/'
                            je ExpDivFx
                            
                            ; checks if ) and end
                            mov bl, Formula[si]
                            cmp bl, ')'
                            jne err4                           
 
                            inc si
                            
                            ; base divide
                            mov bl, Formula[si]
                            cmp bl, '/'
                            je DivFx
                            
                            ; end of formula    
                            mov bl, Formula[si]
                            cmp bl, 0Dh 
                            je outE
                            
                            ; other key scans as error
                            ;------------------------
                            err4:
                                call Throw
                                jmp outE
                            ;------------------------
                            ExpDivFx:
                                inc si     
                                call _clearAscii
                            addExpDiv:
                                mov bl, Formula[si] 
                                
                                call getNumber 
                                
                                mov bl, Formula[si]
                                cmp bl, ')'
                                je endExp2 
                                
                                jmp addExpDiv                                
    ; ====================================================                
    endExp2:
        ; convert ExpDiv for Exp graph 
        push si
        call ASCIITOHEX
        pop si
        
        mov ax, asciiHex[2]
        mov ExpDiv, ax 
        
        inc si 
        
        ; check if has / next           
        mov bl, Formula[si]
        cmp bl, '/'
        je DivFx 
        
        ; if no then check if last is 0Dh
        ; cmp bl, 0Dh
        
        jmp outE                          
DivFx: 
    inc si   
    call _clearAscii
addTimes:
    mov bl, Formula[si]
    
    call getNumber
    
    mov bl, Formula[si] 
    cmp bl, 0Dh 
    je setTimes    
    
    jmp addTimes
    
    setTimes:         
        push si
        call ASCIITOHEX                      
        pop si
        
        mov ax, asciiHex[2]   
        mov Times, ax 
outE:    
    ret      
_Equation endp               
;===================================================================================
getNumber proc
    ; start with number
    sub bl, 30h
    cmp bl, 9
    ja error
    cmp bl, 0
    jl error         
    add bl, 30h
    
    ; convert gradient to base
    mov asciiIn[di], bl
    inc di
    inc si 
    
    ret 
error:        
    call Throw
    pop dx          ; pop ret address    
    
    ret    
getNumber endp    
;=================================================================================== 
_clearVar proc 
    xor cx, cx
    lea di, Buffer
    lea si, Formula
    mov cl, max
    rep movsb
               
    mov ax, 1    
          
    mov Times, ax
    mov gradient, ax
    mov gradient_sign, ax
    mov exp, ax
    mov ExpSign, ax
    mov ExpDiv, ax
    mov iBase, ax  
    mov BaseSign, ax
    
    and base, 0
    and xFlag, 0
    and errBool, 0 
    
    mov bx, -60
    mov x, bx
    
    xor di, di
    xor si, si
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx
    xor cx, cx 
        
    ret
_clearVar endp                
;===================================================================================
_clearAscii proc
    mov cx, 10   
    xor di, di
    c:                     
        mov dl, "$"       
        mov asciiIn[di], dl
        inc di
        loop c
    xor di, di       
    
    mov al, "1"
    mov asciiIn[0], al     
        
    ret
_clearAscii endp 
;===================================================================================
_Axis proc
    mov bx, 100
    mov ax, Def_size             
    mul bx     
    add ax, 0
    push ax
    
    cld         
    mov al, 0Fh          ; color horizontal
    mov cl, 65  
    mov dl, 7 
    pop di
    rep stosb 
               
    xor si, si              
Ax1:  
    mov bx, si
    mov ax, Def_size
    mul bx
    add ax, 160
    push ax
        
    cld         
    mov al, 0Fh        ; color vertical
    mov cl, 1  
    mov dl, 7 
    pop di
    rep stosb
    
    inc si
    cmp si, 200
    jne Ax1  
    ret                                  
_Axis endp   

END MAIN
