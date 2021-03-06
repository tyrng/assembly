.MODEL SMALL
.STACK 64
.DATA

stringInput DB 3,6,0,9,0
tens DW 10000,1000,100,10,1
inputVar DW ?
outputVar DW ?
StringOutput DB 30H,30H,30H,30H,30H


.CODE

MAIN PROC
 MOV AX,@DATA
 MOV DS,AX

 CALL _STRINGVAR
 CALL _FORMULAOP
 CALL _VARSTRING

EXIT:
 MOV AX,4C00H
 INT 21H

MAIN ENDP  

_STRINGVAR PROC ; CONVERT INPUT STRING TO A SINGLE VARIABLE
 MOV BX,0
 MOV SI,0
 MOV DI,0

STRINGVAR:
 MOV AX,0
 MOV AL,stringInput[SI]
 MUL tens[DI]
 ADD BX,AX
 INC SI
 ADD DI,2

 CMP SI,4
 JBE STRINGVAR
 MOV inputVar,BX
 RET
_STRINGVAR ENDP

_FORMULAOP PROC ; FORMULA OPERATIONS 
 ;EXAMPLE
 ;ADD inputVar,...

 MOV BX,inputVar ; TEMPORARY
 MOV outputVar,BX ; TEMPORARY
  
 ;MOV outputVar,... 
 RET
_FORMULAOP ENDP   

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

 MOV AH,02H
 MOV DL,stringOutput[SI]
 INT 21H

 INC SI
 ADD DI,2
 
 CMP SI,4
 JBE VARSTRING
 JA EXIT
 RET        
_VARSTRING ENDP
    
END MAIN
