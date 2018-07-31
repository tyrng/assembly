.MODEL SMALL
.STACK 64
.DATA


; -------- (ASCIITOHEX) ASCII INPUT TO HEX DOUBLE WORD --------
; ASCII INPUT (UNTOUCHED)
asciiIn     DB  "$$$$$$$$$$$" 
; ASCII INPUT (ADDZEROS)
asciiInZ    DB      10 DUP(48),"$"
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
hexAscii    DB  12 DUP("$")

; ------- (ASCIITOHEX,HEXTOASCII) SHARED  ---------------------
; CURRENT INDEX OF ASCII INPUT IN DECIMAL STRING (EG '3' of '4321' IS INDEX 1)
zeroIndex   DW  ?
; PAIRS OF ZEROS IN DOUBLE WORD HEX, STARTING FROM 1,000,000,000 (15258,51712)          
zeroPairs   DW  15258,51712,1525,57600,152,38528,15,16960,1,34464,0,10000,0,1000,0,100,0,10,0,1

; ------------------ (IN2POST) INFIX TO POSTFIX ---------------
; INFIX LIST        127 CHARACTERS LIMIT
inList      DB  "(4543.2 + 34234.4) x 66 - (2123 - 23245) x (6456 + 35465)", 70 DUP("$")
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

; ------------------ (dpConvert) DECIMAL POINT CONVERTER, CONVERT 0 OR 1 DP TO 2 DP (RUN TWICE FOR 0DP to 2DP) ----------------------
dpConv      DW  0,0


num1        DW  0,0
num2        DW  0,0
ans         DW  0,0

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    
    CALL IN2POST
	
	CALL POSTOPS
	
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
    
    PUSH 40 ; PUSH INITIAL PARENTHESIS "("
    
    MOV SI,0
    MOV DI,0
    
    ; GENERAL CHAR CHECKING
    I2P_L1:
        MOV AL,inList[SI]
        
        CMP AX,36           ; $
        JE I2P_RIGHTP
        CMP AX,32           ; space
        JE I2P_SKIP
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
        JB I2P_INVALID
        CMP AX,57           ; operands
        JA I2P_INVALID
        
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
                JE I2P_EXIT
                INC SI          ; FORWARD inList
                JMP I2P_L1
                
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
    
    PO_L1:                  ; IMPORTANT : FROM HERE ON DO NOT CLEAR AX AND SI
        MOV AL,postList[SI]                         
        
        CMP AX,36           ; $
        JE PO_END
        CMP AX,43           ; +
        JE PO_OPERATOR
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
            XOR BX,BX
            XOR DX,DX
            MOV dotTrigger,DL       ; RESET DOT TRIGGER (0 - NONE, 1 - EXISTS, MORE THAN 1 - ERROR)
            MOV countPostDot,DL     ; RESET DECIMAL COUNT AFTER DOT
            
            INC SI                  ; SKIP OPERAND OPENING {
            
            
            PO_NUMBERS:
                
                MOV AL,postList[SI]
                
                ; CHECK FOR } and .
                
                CMP AX,125          ; OPERAND CLOSING }
                JE PO_CLOSING 
                CMP AX,46           ; DECIMAL DOT .
                JE PO_DOT
                
                ; IF NOT } AND .
                
                MOV tempOpStr[DI],AL; INSERT TO TEMP OPERAND STRING
                INC DI
                
                XOR DX,DX
                MOV DL,dotTrigger
                CMP DX,0
                JBE PO_SKIPADDDOT
                
                INC BL
                MOV countPostDot,BL ; ADD COUNT FOR DECIMAL AFTER DOT
            
            PO_SKIPADDDOT:          ; NO DECIMAL
                
                INC SI              ; FORWARD postList
                JMP PO_NUMBERS
                
            PO_DOT:
                XOR DX,DX
                MOV DL,dotTrigger
                CMP DL,0            ; DETECTS MULTIPLE DOTS AND PROMPT ERROR
                JA PO_ERROR
                
                MOV DX,1            ; DOT DETECTED
                MOV dotTrigger,DL
                
                XOR DX,DX
                
                INC SI              ; FORWARD postList
                JMP PO_NUMBERS
                
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
                
                CALL ASCIITOHEX
                
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
                JA PO_ERROR
                
                PO_xDP:             ; BETWEEN 3 TO 5 DIGITS
                    ; PENDING   
                
                
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
                    
                    MOV DX,tempOpHex[2]
                    PUSH DX
                    MOV DX,tempOpHex[0]
                    PUSH DX
                    
                    INC SI          ; FORWARD postList
                    JMP PO_L1
                
            
        PO_OPERATOR:    
            
        
        PO_ERROR:
            MOV SP,0
            
        PO_END:
            
            
        
    
    
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
    ;LOOP 10 TIMES FOR 10 DIGIT NUMBER
    MOV CX,10
    MOV SI,0
    ASCII2NUM:        
    
        MOV AL,asciiInZ[SI]
        SUB AL,30H
        MOV asciiInNum[SI],AL
    
        INC SI
        
        LOOP ASCII2NUM
    RET
ASCIITONUM ENDP

ZEROLOOPER PROC
    ;INSERT INDEX HERE (CHANGE '0' TO VARIABLE)
	MOV SI,0	       
	
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

END MAIN
