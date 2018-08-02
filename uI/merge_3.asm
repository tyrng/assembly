.MODEL SMALL
.STACK 64
.DATA


; -------- (ASCIITOHEX) ASCII INPUT TO HEX DOUBLE WORD --------
; ASCII INPUT (UNTOUCHED)
asciiIn     DB  "$$$$$$$$$$$" 
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
; INFIX LIST        127 CHARACTERS LIMIT
inList      DB  "(14356.278 + 53888.4) x 16q + (423 - 114) x (656 + 665) + 4^4 + 10000000", 55 DUP("$")
; POSTFIX LIST      127 CHARACTERS LIMIT
postList    DB  127 DUP("$")


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

; ----------- ERRORFLAG (AFTER EQUALS) ------------------
errorFlag   DB  ?

;GENERAL VARIABLES
num1 dw 0000H, 0000H
num2 dw 0000H, 0000H


ans dw 0000H, 0000H

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

;ERROR MEESAGE STRINGS
err db 0
err_str1 db "SYNTAX ERROR!$",10,13,24

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    
    CALL IN2POST
	
	CALL POSTOPS
    
    CALL HEXTOASCII
    
    CALL ADDDOT
    
    CALL CLREG
    
    MOV AH,09H
    LEA DX,asciiDot
    INT 21H
	
	EXIT:		  
    MOV AX,4C00H
    INT 21H

MAIN ENDP



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

; INFIX TO POSTFIX GENERAL FUNCTION
IN2POST PROC
    CALL CLREG
    
    XOR AX,AX
    MOV AL,40
    
    PUSH AX ; PUSH INITIAL PARENTHESIS "("
    
    XOR AX,AX
    
    MOV SI,0
    MOV DI,0
    
    ; GENERAL CHAR CHECKING
    I2P_L1:
        MOV AL,inList[SI]
        
        CMP AX,36           ; $
        JE I2P_RIGHTP
        CMP AX,32           ; space
        JE E_I2P_SKIP
        CMP AX,40           ; (
        JE I2P_LEFTP        
        CMP AX,41           ; )
        JE I2P_RIGHTP       
        CMP AX,43           ; +
        JE I2P_OPERATOR
        CMP AX,45           ; -
        JE I2P_OPERATOR
        CMP AX,120          ; x
        JE I2P_OPERATOR
        CMP AX,47           ; /
        JE I2P_OPERATOR
        CMP AX,115          ; s (squared)
        JE I2P_OPERATOR
        CMP AX,94           ; ^ (power)
        JE I2P_OPERATOR
        CMP AX,113          ; q (square root)
        JE I2P_OPERATOR
        CMP AX,46           ; . (decimal dot)
        JE I2P_OPERAND
        CMP AX,48           ; operands
        JB E_I2P_INVALID
        CMP AX,57           ; operands
        JA E_I2P_INVALID
        JMP I2P_OPERAND
        
        E_I2P_SKIP:
            JMP I2P_SKIP
            
        E_I2P_INVALID:
            JMP I2P_INVALID
        
        I2P_OPERAND:
        MOV BL,123          ; ADD OPERAND OPENING {
        MOV postList[DI],BL
        INC DI              ; FORWARD postList
        
        I2P_OPERAND2:
            MOV postList[DI],AL ; ADD OPERAND
            INC DI              ; FORWARD postList  
            
            INC SI              ; FORWARD inList
            MOV AL,inList[SI]
        
            ; CHECK NEXT CHAR FOR OPERAND
            CMP AX,46
            JE I2P_OPERAND2                
            CMP AX,48           ; operands
            JB I2P_OPERANDOUT
            CMP AX,57           ; operands
            JA I2P_OPERANDOUT
        
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
                
            I2P_PREC10:         ; PRECEDENCE LEVEL 10 : x /    
                CMP BX,120
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
                
                I2P_SQRT:       ; ADD {2} TO postList FOR SQUARED (2 IS ACTUALLY A DUMB VALUE)
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
        MOV SP,0
        CALL CLREG
        
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
    
    MOV SI,0
    MOV postSI,SI
    
    PO_L1:                  ; IMPORTANT : FROM HERE ON DO NOT CLEAR AX AND SI
        XOR AH,AH
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
                JA E_PO_ERROR
                
                MOV DX,1            ; DOT DETECTED
                MOV dotTrigger,DL
                
                XOR DX,DX
                
                INC SI              ; FORWARD postList
                MOV postSI,SI
                JMP PO_NUMBERS
                
                E_PO_ERROR:
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
                CMP BL,5            ; MORE THAN 5 DIGITS
                JA E_PO_ERROR
                
                PO_xDP:             ; BETWEEN 3 TO 5 DIGITS
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
                
                PO_1DP:             ; ADD ZEROS (CONVERT TO 2DP)
                    CALL dpConvert
                
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
            CMP AX,47           ; /
            JE PO_DIVISION
            CMP AX,115          ; s (squared)
            JE PO_POWER
            CMP AX,94           ; ^ (power)
            JE PO_POWER
            CMP AX,113          ; q (square root)
            JE E_PO_SQRT
            JMP PO_ADDITION
            
            E_PO_SQRT:
                JMP PO_SQRT
            
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
                MOV BX,ans[2]
                PUSH BX
                MOV BX,ans[0]
                PUSH BX   
                
                MOV SI,postSI
                INC SI
                MOV postSI,SI
                JMP PO_L1    
             
        
        PO_ERROR:
            MOV SP,0 ; PENDING
            
        PO_END:
            POP AX              ; FINAL ANSWER
            MOV hexIn[0],AX
            POP AX
            MOV hexIn[2],AX
            
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

mov ax, ans[0]
mov bx, ans[2]

mov dpConv[0], ax
mov dpConv[2], bx

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
	    A_REZEROS:
	        MOV asciiInZ[SI],48
	        INC SI
	        LOOP A_REZEROS    
	    
	    
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
            
;                AD_0D:
;                MOV AL,hexAscii[SI]
;                MOV asciiDOt[SI],AL    
            
        AD_CONTINUE2:
            CALL CLREG
            
            RET
            
ADDDOT ENDP

ERROR_MSG PROC

mov ah, 09H
lea dx, err_str1
int 21H

ret 
ERROR_MSG ENDP

power PROC
;====================WELCOME TO THE POWER FUNCTION==============

;--ERROR CHECKING---
cmp ans[0], 0H
JNE ERROR_MSG
JNZ  pow_exit

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

mov ans, ax   
   
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
mov ans, ax

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
add cx, ax
mov bx, dx
jnc mul_move
add bx, 1H

mul_move:
mov ax, num1[2]
mul num2
add cx, ax
mov ans[0], cx
mov cx, dx

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

mov ax, ans[0]
mov bx, ans[2]

mov num1[0], ax
mov num1[2], bx

mov ax, temp_rmdr
mov num2[2], ax

call addition

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

fild int32        ;load the integer to ST(0)
fsqrt             ;compute square root and store to ST(0)
fistp squareRoot  ;store the result in memory (as a 32-bit integer) and pop ST(0)

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

END MAIN
