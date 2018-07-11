.MODEL SMALL
.STACK 64
.DATA

; -------- (ADDZEROS) ADD REQUIRED ZEROS TO ASCII INPUT -------
; ASCII INPUT (UNTOUCHED)
asciiInRaw	DB		"$$$$$$$$$$$"
; ASCII INPUT (ADDZEROS)
asciiInZ    DB      "$$$$$$$$$$$"

; -------- (SUBZEROS) SUB REQUIRED ZEROS TO ASCII OUTPUT -------
; ASCII OUTPUT (UNTOUCHED)
asciiOutRaw DB      "$$$$$$$$$$$"
; ASCII OUTPUT (SUBZEROS)
asciiOutZ   DB      "$$$$$$$$$$$"

; -------- (ASCIITOHEX) ASCII INPUT TO HEX DOUBLE WORD --------
; ASCII INPUT (IN STRING)
asciiIn     DB  "$$$$$$$$$$$"
; ASCII INPUT (IN DECIMAL)
asciiInNum  DB  10 DUP(?)
; HEX OUTPUT (IN HEX DOUBLE WORD)
asciiHex    DW  0,0 

; -------- (HEXTOASCII) HEX DOUBLE WORD TO ASCII OUTPUT -------
; HEX INPUT (IN HEX DOUBLE WORD)
hexIn       DW  ?,?
; ASCII OUTPUT (IN DECIMAL)
hexAsciiNum DB  10 DUP(0)
; ASCII OUTPUT (IN STRINGS)
hexAscii    DB  10 DUP(?),"$"

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

; ADD REQUIRED ZEROS TO ASCII INPUT FOR ASCIITOHEX ---------------------------------------------
ADDZEROS PROC
	
	CALL CLREG
	
	MOV SI,0
	A_COUNTZEROS:
	    MOV AL,asciiInRaw[SI]
	    INC SI
	    CMP AL,36
	    JNE A_COUNTZEROS
	
	    MOV BX,11
	    SUB BX,SI
	    MOV DX,BX
	    MOV CX,SI
	    MOV SI,0
	    A_TRANSFER:
	        MOV AL,asciiInRaw[SI]
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

; SUBTRACT REQUIRED ZEROS TO ASCII INPUT FOR ASCIITOHEX ----------------------------------------
SUBZEROS PROC    
    CALL CLREG
    
    MOV SI,9 ; LOOP FROM END
    S_COUNTNUM:
        MOV AL,asciiOutRaw[SI]
        CMP AL,48
        JE S_CONT
        DEC SI
        JMP S_COUNTNUM
        
    S_CONT:
        MOV DI,SI
        INC DI
        MOV CX,DI
        MOV SI,0
        
        
        S_TRANSFER:
            MOV AL,asciiOutRaw[DI]
            MOV asciiOutZ[SI],AL
            INC SI
            INC DI
            LOOP S_TRANSFER
    
    CALL CLREG
    RET
SUBZEROS ENDP

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
    
    MOV CX,2
    MOV SI,0
    CL_ASCIIHEX:
        MOV asciiHex[SI],0
        INC SI
        LOOP CL_ASCIIHEX         
                   
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
    
        MOV AL,asciiIn[SI]
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

; HEXADECIMAL DOUBLE WORD (STORED IN TWO WORDS) TO ASCII STRING --------------------------------

HEXTOASCII PROC
    MOV AX,0
    MOV zeroIndex, AX 
    
    CALL CLREG
    
    MOV CX,10
    MOV SI,0
    CL_HEXASCIINUM:
        MOV hexAsciiNum[SI],0
        INC SI
        LOOP CL_HEXASCIINUM
    
    CALL CLREG
    
    MOV AX,hexIn[0]
    MOV BX,hexIn[2]
    MOV SI,zeroIndex
    ; AT THIS POINT AX, BX AND SI ARE USED
    ; FROM THIS POINT DO NOT CLREG
    
    CHECKNLOOP:
    
    
        MOV DI,zeroPairs[SI]
        MOV DX,zeroPairs[SI+2]
        CMP DI,AX
        JA XSAFE2SUB
        JB SAFE2SUB
        CMP DX,BX
        JBE SAFE2SUB
        JA XSAFE2SUB        
    
        SAFE2SUB:
            CALL FILLWATER
            JMP ZEROSOP2
    
    
        XSAFE2SUB:
            ADD SI,4
            CMP SI,36
            JBE CHECKNLOOP
            JA  XCHECKNLOOP
            
        ZEROSOP2:    
            CMP SI,0
        	JE ZERO0B    
	        CMP SI,4
    	    JE ZERO1B    
    	    CMP SI,8
	        JE ZERO2B    
	        CMP SI,12
    	    JE ZERO3B    
	        CMP SI,16
    	    JE ZERO4B    
	        CMP SI,20
    	    JE ZERO5B    
    	    CMP SI,24
	        JE ZERO6B    
	        CMP SI,28
	        JE ZERO7B    
	        CMP SI,32
	        JE ZERO8B
	        CMP SI,36
	        JE ZERO9B    
	    
	ZERO9B:
	    INC hexAsciiNum[9]
	    JMP CHECKNLOOP
	
	ZERO8B:
	    INC hexAsciiNum[8]
	    JMP CHECKNLOOP
	
	ZERO7B:
	    INC hexAsciiNum[7]
	    JMP CHECKNLOOP
	
	ZERO6B:
	    INC hexAsciiNum[6]
	    JMP CHECKNLOOP
	
	ZERO5B:
	    INC hexAsciiNum[5]
	    JMP CHECKNLOOP
	
	ZERO4B:
	    INC hexAsciiNum[4]
	    JMP CHECKNLOOP
	
	ZERO3B:
	    INC hexAsciiNum[3]
	    JMP CHECKNLOOP
	
	ZERO2B:
	    INC hexAsciiNum[2]
	    JMP CHECKNLOOP
	
	ZERO1B:
	    INC hexAsciiNum[1]
	    JMP CHECKNLOOP
	
	ZERO0B:
	    INC hexAsciiNum[0]
	    JMP CHECKNLOOP
	
	XCHECKNLOOP:
	    CALL CLREG
	    
	    CALL NUMTOASCII
	    
        RET
        
    
HEXTOASCII ENDP

NUMTOASCII PROC
    MOV CX,10
    MOV SI,0
    NUM2ASCII:
        
        MOV AL,hexAsciiNum[SI]
        ADD AL,30H
        MOV hexAscii[SI],AL
        
        INC SI
        
        LOOP NUM2ASCII
    
    CALL CLREG
    
    RET

NUMTOASCII ENDP

FILLWATER PROC ; HEX1: AX, HEX2: BX (DO NOT CLREG BEFORE AND AFTER EXCEPT ANSWER IS RETRIEVED)
    MOV DX,zeroPairs[SI+2]
    MOV BP,zeroPairs[SI] 
    SUB BX,DX
    SBB AX,BP
    RET
FILLWATER ENDP

END MAIN
