.MODEL SMALL
.STACK 64
.DATA

;------------------------------------
stringInput DB 1,2,3,4,5	;Loan Amount Array
tens DW 10000,1000,100,10,1
inputVar DW ?	;Loan Amount (Decimal Form)
outputVar DW ?
StringOutput DB 30H,30H,30H,30H,30H
nLine DB 10,13,"$"
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
drama DB "COMMENCING LOAN COMPUTATION...$"
looper DB 2


;========MONTHLY LOAN PAYMENT VARIABLES==========
loanXinterest DW ?
loanDP DW ?

d_loopVar DW ?
denomVar DW ?
	
mLoanPayment DW ?
mLoanPayment_DP DW ?

.CODE

MAIN PROC
 MOV AX,@DATA
 MOV DS,AX

 
 TESTING:
 CALL _STRINGVAR
 CALL _CONST_SETTING	;---Set constant array---
 CALL _MONTHLY_LOAN ;--test
 CALL _VARSTRING
 ;-------------
 CALL _FINALOAN
 CALL _VARSTRING
 
  
 XOR AX, AX 
 MOV AL, looper
 SUB AL, 1
 MOV looper, AL
 
 CMP AL, 0
 JE MAIN_EXIT
 JA TESTING 

MAIN_EXIT:
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
 
 ;---Intro (NOT NEEDED)
 MOV AH,09H
 LEA DX,drama
 INT 21H
 
 ;---Newline
 MOV AH,09H
 LEA DX,nLine
 INT 21H
 
 ;---LOOP SETTINGS---
 XOR AX, AX
 MOV AL, nVar
 MUL tVar
  
 ;---Initializing loop---
 MOV CX, AX
 SUB CX, 1
 MOV AX, constantVar
 MOV fPoint, AX  
 
 BIGASSLOOP:

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
 LOOP BIGASSLOOP
 
 
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
 
 MOV AH, 09H
 LEA DX, nLine
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
    
END MAIN
