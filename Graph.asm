.model small
.stack 100
.data       
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
    exp db 1                        ; x^n , n = 1,2,3  
    
; Variables ================================================================== 
    x_axis dw ?                     ; x axis always double value of x 
    pow_x dw ?
; y variables ---------------------------------------------------------------- 
    pow_y dw ?
    y dw ?                          ; value according to x
    
; Power Graph ===============================================================
    iBase dw 2                      ; Z base (with sign) 
    base dw ?                       ; base number n^x 
    base_gradient dw 1              ; base sign    
    exp_gradient dw 1               ; e^nx
    ExpDiv dw 2                     ; e^x/n
    ExpSign dw 1                    ; sign for exp   
;Input =======================================================================    
    StoreNum db 10 dup ("$")        ; store all numbers 
    xFlag db 0                      ; use X only once
    
    ; Polynomial a(x+b)+c
    ;C dw ?                          ;y=+C
    ;b dw ?                          ;y=bX
    ;term db ?                       ; X^3+X, 2 terms    
                    
    ; do times dw 3, 50, 210        and times[di]   
    ; x range up to -20~20, -60~60 ,-25~25 
    ; n^x x: -10, times : 100,         
    
    ; make a function that compares sign of exp(+/- x) and a variable to jump
.code
main proc
    mov ax, @data
    mov ds, ax  

    push es
                  
    out 0F3h, ax                 
    mov ax, 0A000h
    mov es, ax
    
    mov ax, 13h    
    int 10h    
       
    ;mov ax, 4F02h           ; SUPER VGA MODE
    ;mov bx, 0107h           ; bigger resolution
    ;int 10h
    
    ;call _Axis              ; color works well on emu8086 but not dosbox.. 
    
    call _Equation      
 
    call _Adjustment    
 
    mov ax, -2               ; double the x range and auto fix sign
    imul x
    mov x_axis, ax  
    xor dx, dx               ; clear sign 
    
    cmp x_axis, 0
    jge positive_range 
    
    neg x_axis
    mov bx, 0  
    mov x, bx                ; set x to 0
                          
positive_range:
    
    call _Pixel             ; Remove this when ready 
    
    xor si, si
    mov cx, x_axis
plot_graph:                                 
    push cx                 ; save counter 
;============================================================================                                                         
    call _Parameter_X       ; set x and y coordinates     
    
    xor cx, cx
    cmp exp, 'X'            ; exponential function
    je Exponential
    
    cmp exp, -1
    jle Inverse
    ;jg Function
    
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
    
    mov ah, 1
    int 21h 
    
    pop es                        
 
    mov ax, 3       ; return to text mode
    int 10h         ; auto cls
       
    mov ah, 4ch
    int 21h
main endp 

_Pixel proc                        
    ; graph doesnt go out of screen resolution
    ; remove these to get more accurate graph
    cmp scr_y, 200
    ja no_pixel
    cmp scr_x, 320
    ja no_pixel      
    
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
     
    mov cl, exp                 ; move exp for loop
    dec cl 
    
Power:                          ; exponential function 
    mul pow_x
    loop Power 
     
linear:       
    cmp x, 0                    ; if x is more than 0, then sub
    jg Positive    
    
    mov cl, exp
    test cl, 1
    jz Positive                 ; jump if even function, x^2,4,6, since square always positive
      
Negative:                       ; no sign involve             
    div times                   ; ax=-3 now ax=3 so add
    mul gradient
    add scr_y, ax
       
    jmp exit_graph
Positive:      
    div times                   ; error here 1/3 is 0 integer 
    mul gradient               
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
    
    mov cl, exp
    test cl, 1
    jz Inv_Positive
 
    mul times   
    div pow_x                    ; Negative
    mul gradient   
    add scr_y, ax
    
    jmp Inv_Y_axis               
    ;jmp exit_graph              ; remove extra one and enable this code
Inv_Positive: 
    mul times        
    div pow_x                    ; Positive
    mul gradient
    sub scr_y, ax 
    
    ;jmp exit_graph
; Extra Precise line plotting ==================  
Inv_Y_axis:               
    push x
    pop y   
    
    call _Pixel                 ; color from above
    
    call _Parameter_Y           ; delete the function if no need for extra line plotting
    mov ax, Inv_x 
    cwd      
    
    cmp y, 0
    jz exit_Inv_graph
    jg Inv_Negative
    
    mul times
    div pow_y
    mul gradient
    add scr_x, ax    
    
    jmp exit_Inv_graph  
    
Inv_Negative: 
    mul times
    div pow_y
    mul gradient
    sub scr_x, ax                   
;==================================================
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
    mul exp_gradient            ; a^(nx)
    div expDiv                  ; for a^(x/n)
    mov cx, ax                  ; set for loop
    pop ax                                                                                     
    
    push iBase                  ; set 'iBase' to 'base'
    pop base                                      
                                                       
    cmp iBase, 0                ; checks if Z+ base is negative
    jge skip_base
    
    neg base                    ; if base is negative, negate   -a*n
    neg base_gradient           ; separate sign from 'base'     -a = base gradient
    
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
    ;mul gradient
    mul base_gradient      
    sub scr_y, ax    
    
    jmp exit_exp      
    
Exp_Negative:                   
    mul gradient
    div times                   
    ;mul gradient                ; divide overflow
    mul base_gradient        
    add scr_y, ax               ; go down

exit_exp:  
    ret       
_Exponential endp 
;===================================================================================
_Adjustment proc
    ; Times adjustment for later division  
    xor cx, cx   
    mov cl, exp              ; set for all graph gradient 
    cmp cl, 'X'
    jne set_range            ; NOT EQUAL
; -------------------------------------------------------------------------
    mov ax, gradient
    mov bx, times
    div bx 
    
    cmp ax, 10
    jl noSetTimes   
    
    add ax, ax              
    mov times, ax
    
    mov ax, exp_gradient
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
    cmp cl, 3               ; both -3 and 3 
    jb exit_set 
    
    sub cl, 3   
    mov si, cx   
                                                                  
    mov ax, 0Ah             ; x starts at negative
    mov bx, ax              ; ax = bx                 
                                                      
mul_loop:                   ; x^3 = 10, x^4 = 100 x^5 = 1000
    mul bx
    jc stop_mul             ; this doesnt calculate minimum 'times' value for divide
    dec si  
    cmp si, 0
    jne mul_loop   

stop_mul:                                                                
    cmp ax, times                ; times has to be atleast x10 of x
    jle exit_set                 ; before was jbe, has sign flag 
                 
    ; else set times at least 100
    mov ax, x                ; minimum times value * 10
    neg ax 
    cwd                      ; just to make sure, exp can go above 35  

loop_times:   
    mul bx                   ; bx = 0Ah from above
    jc stop_loop                         
    loop loop_times 
                                          
stop_loop:    
    add x, bx                ; reduce bx by 10 <<<<<<<<<<<<<<<<<, remove if no use
    
    xor dx, dx               ; lower ax into times 
    mov times, ax   
; -------------------------------------------------------------------------                  
exit_set:                              
    ret
_Adjustment endp    
;===================================================================================
_Parameter_X proc               ; this function sets x and y and neg signed values
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
_Parameter_X endp 
;===================================================================================
_Parameter_Y proc
    ; y variable --------------------------------------------------
    push coordxy[2]         
    pop scr_y                   ; set x screen coordinate 
   
    mov bx, y                   ; bx=-20 
    and bx, bx                  ; set sign flag
    add scr_y, bx               ; 160-20   
    inc y                       ; y starts from -20 to positive 20  
    inc scr_y
   
    ; x variable ----------------------------------------- 
    push coordxy[0]        
    pop scr_x                   ; put y for screen position   
    
    push y
    pop pow_y                   ; set pow_y from y
    
    cmp y, 0
    jge skip_neg_1                ; if y is negative then negate pow_y, avoid div overflow
  
    neg pow_y                   ; no overflow cause  
skip_neg_1:   
    ret
_Parameter_Y endp
;===================================================================================
_Equation proc             
    ; note that theres no need to enter '*' or multiply 'x'              
    ; planned to have -N(-X+A)^(-NX/B)+C
    ; 1. scans an equation from user, only supports y function
    ; 2. print Y, use has to put capital X
    ; 3. scans if first index has '-', negate after step 4. for gradient
    ; 4. scans if next index is number then assign to gradient
    ; 5. scans if next index has X or R for real numbers 
    ; 6. scans if next index has ^ 
    ; 7. scans if next index has ( else then only X or R 
    ; 8. if has ( next has to be X and /, end with )     
    ; 9. if has ( next has is a number then followed with x 
    ; 10. after ) can add + and - and /      
    mov ah, 2
    mov dl, "Y"
    int 21h 
    
    mov ah, 2
    mov dl, "="
    int 21h
    
Fx_In:     
    mov ah, 1
    int 21h
    
    cmp al, '^'
    je Fx_pow
    
    cmp al, '/'
    je Fx_div
    
    cmp al, 'X'
    je Fx_var 
    
    cmp al, 0Dh
    je Fx_Ext
    
    sub al, 30h
          
    cmp al, 0         
    jae Fx_Num
    cmp al, 9
    jbe Fx_Num
    
    jmp Fx_In
    
Fx_var:          
    or xFlag, 1                 ; X variable only once
    jmp Fx_in 
    
Fx_Num:           
    mov bl, "1"
    ;mov asciiIn[2], bl
                            
    xor si, si
    loopHex:     
        mov ah, 1
        int 21h
        
        sub al, 30h
        
        cmp al, 0
        jb outNum
        cmp al, 9
        ja outNum
        
        add al, 30h
            
        ;mov asciiIn[si], al
        inc si             
        
        jmp loopHex
    
    outNum:       
        ;call ASCIITOHEX
            
        ;mov ax, asciiHex[2]         ; ax = gradient
        imul gradient_sign
        mov gradient, ax 
        
        xor si, si             
        
    jmp Fx_In
    
negSign:
    cmp xFlag, 0                ; 1 = Normal graph, 0 = Exp
    jz Fx_Exp
        
        neg gradient_sign
        jmp Fx_In
    
    Fx_Exp:
        neg ExpSign
        jmp Fx_In
         
Fx_Pow:      
    ; print ^( after type ^
    mov bl, "1"
    ;mov asciiIn[2], bl 
    
    cmp xFlag, 0                
    jz Fx_xExp
                
        mov bl, 'X'               
        mov exp, bl
        jmp Fx_In
    
    loop_xExp:    
        mov ah, 1
        int 21h  
        
        sub al, 30h
        
        cmp al, 0
        jb outNum1
        cmp al, 9                  ;<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< STOPPED hEre
        ja outNum1
        
        add al, 30h
            
        ;mov asciiIn[si], al
        ;inc si             
        
        jmp loop_xExp
    
    outNum1:       
        ;call ASCIITOHEX
            
        ;mov ax, asciiHex[2]         ; ax = gradient
        imul ExpSign
        mov exp_gradient, ax 
        
        xor si, si             
        
    jmp Fx_In
        
        

Fx_Ext:    
    
    ret               
_Equation endp                
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
L1:  
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
    jne L1  
    ret                                  
_Axis endp      

end main