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
; INFIX LIST
inList      DB  "(123+321)x5-(44-33)x(33+66)$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"
; POSTFIX LIST
postList    DB  "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$"
; 


; OPERANDS
i2pOp1      DW  0,0
i2pOp2      DW  0,0

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    
    CALL IN2POST
	
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
        CMP AX,48           ; operands
        JB I2P_INVALID
        CMP AX,57           ; operands
        JA I2P_INVALID
        
        ; I2P_OPERAND
        MOV BL,123          ; ADD OPERAND OPENING {
        MOV postList[DI],BL
        INC DI              ; FORWARD postList
        
        
        
        I2P_OPERAND2:
            MOV postList[DI],AL ; ADD OPERAND
            INC DI              ; FORWARD postList  
            
            INC SI              ; FORWARD inList
            MOV AL,inList[SI]
        
            ; CHECK NEXT CHAR FOR OPERAND
                            
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
                
        
        I2P_INVALID:
        
    I2P_EXIT:  
    
      
        RET    
        
IN2POST ENDP
































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


END MAIN
