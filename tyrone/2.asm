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

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    
    CALL ASCIITOHEX
	
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
