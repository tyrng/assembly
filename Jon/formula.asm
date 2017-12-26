.MODEL SMALL
.STACK 64
.DATA

stringInput DB 1,1,1,1,1
tens DW 10000,1000,100,10,1
inputVar DW ?
outputVar DW ?
StringOutput DB 30H,30H,30H,30H,30H
nLine DB 10,13,"$"

;---Interest Rate(10%)
rate DB 30H

;---Number of years the loan is borrowed for
tVar DB 2

;---Number of times the interest is compounded annually
nVar DB 12

;---(N x T) variable
ntVar DB ?

;---(1 + R/N)variable
constantVar DW 1010
cString DW 1,0,1,0

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
drama DB "COMMENCING LOAN COMPUTATION...$"

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
 ;=============Setting up loop================
 
 ;---Intro
 MOV AH,09H
 LEA DX,drama
 INT 21H
 
 MOV AH,09H
 LEA DX,nLine
 INT 21H
 
 ;---LOOP SETTINGS---
 MOV AX, 0000H
 MOV AL, nVar
 MUL tVar
  
 ;---Initializing loop---
 MOV CX, AX
 SUB CX, 1
 MOV AX, constantVar
 MOV fPoint, AX  
 
 BIGASSLOOP:

 MOV BX, 0
 MOV DX, 0
 
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
 LOOP BIGASSLOOP
 
 
 
 ;==========CALCULATION PART II===========
 ;(Multiplying loan with compounded rate)
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
 JE SETUP_BM
 JA DECREMENT
 
 DECREMENT:
 SUB SI, 2
 JMP FP_SEPERATOR
 
 
 SETUP_BM:
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
 JB RETURN

 
 DP_ROUNDUP:
 MOV AX, decimalPoint
 INC AX
 MOV decimalPoint, AX
 
 JMP RETURN
 
 
 ;---RETURN FINAL COMPOUNDED LOAN VALUES
 RETURN:
 MOV AX, totalLoan
 MOV outputVar, AX
 
 
 ;-----------------------------
 ;MOV BX,inputVar ; TEMPORARY
 ;MOV outputVar,BX ; TEMPORARY
 
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
 JA DECIMAL_PRINT
 
 ;---Print out remaining decimals
 DECIMAL_PRINT:
 XOR DX, DX
 
 MOV AH, 02H    ;---Print out '.'
 MOV DL, 2EH
 INT 21H
 
 XOR DX, DX
 
 MOV AX, decimalPoint
 DIV tens[6]
 
 ADD dpString[0], AL
 ADD dpString[1], DL
 
 MOV AH, 02H
 MOV DL, dpString[0]
 INT 21H
 
 MOV AH, 02H
 MOV DL, dpString[1]
 INT 21H
 
 JMP EXIT2
 
EXIT2:
 JMP EXIT 
 
 RET        
_VARSTRING ENDP
    
END MAIN