.model small
.stack 100
.data     
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
    String db 71 dup("$")       ; accept keys           
    inLimit dw 70d              ; limit for input, word size for 16 bit reg            
    inPtr dw ?                  ; input string pointer    
    DigitF db ?                 ; bool variable for checking zero as front digit
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
    array_button dw 1F73h, 075Eh, 0001h, 011Bh, 326Dh
                 dw 1071h, 0001h, 0001h, 1265h, 0001h
                 dw 0001h, 2E63h, 0001h, 0E08h, 352Fh 
                 dw 1970h, 0837h, 0938h, 0A39h, 2D78h
                 dw 0221h, 0534h, 0635h, 0736h, 0C2Dh          
                 dw 0001h, 0231h, 0332h, 0433h, 0D2Bh
                 dw 0A28h, 0B29h, 0B30h, 342Eh, 1C0Dh                   

    ; BH = 8F, 80h causes blinking screen
    ; 25 row and 80 column max 
    ; max cursor range cx: column 027Fh dx: row 0C7h             
.code                                                          
main proc
    mov ax, @data
    mov ds, ax    
; START SETUPS--------------------------------------    
    call cls
    call _Calc_UI              
    call _Calculator            ; Begins here
    
    mov ah, 4ch
    int 21h     
main endp            

; TINY FUNCTIONS ==============================================
sleep proc
    ; set 1 million microseconds interval (1 second)
    ;mov cx, 0fh        
    ;mov dx, 4240h 
; modified count ------------------------- SET TIMER HERE
    mov cx, 1h          ; high order word  
    mov dx, 1h          ; low word
    mov ah, 86h
    int 15h
    ret

print proc
    mov ah, 9
    int 21h
    xor dx, dx
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
    mov dx, 0700h           ; display buttons   
    call cursor
    
    lea dx, scanf    
    call print  
    
    mov dh, String_y        ; constant row
    mov dl, String_x        ; constant column 
    
    mov Update_Col, dl      ; reset    
       
    call cursor 
    
    xor si, si  
    xor di, di   
    
    mov ah, 2
    mov dl, 30h    
    int 21h          
       
    mov inPtr, si           ; clear input size    
          
    ret   
    
clstr proc                                                                
    mov cx, inPtr        
    xor di, di
    mov al, "$"
t:     
    mov tempStr[di], al
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
    mov ax, dx                      ; ax has row coord
    mov bx, cx                      ; bx has col coord  

    xor cx, cx
    xor dx, dx 
    xor si, si
           
    mov cl, start_Row               ; upper row      3F19h
    mov dl, end_Row                 ; lower row                            
Outer_Loop:    
    push cx                         ; save upper row coord
    push dx                         ; save lower row coord  
    
    cmp ax, cx                      ; compare if it's in current row 
    jb break_1             
    cmp ax, dx
    ja break_1       
    
    mov cx, start_Col               ; upper Col
    mov dx, end_Col                 ; lower Col
    
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
    
    cmp dx, 00B7h                      ; compare lower row to maximum depth
    jne Outer_Loop 
    
    xor ax, ax
    jmp no_button                       ; no button scanned then out
    
operation:  
    pop dx                            ; avoid stack having previous values
    pop dx                            ; clear, This     
    mov ax, array_button[si]   
       
    cmp ax, array_button[8]           ; Switch mode
    jne no_button                     ; if ax = "m", no jump
                      
right_button:                          
    mov ax, array_button[8]
    call _KeyPress             
    dec Mode                      ; Mode = 0, Keyboard mode  
    
    mov ax, 2                      ; hide cursor 
    int 33h    
    
    xor ax, ax      
no_button:   
    mov upperIn, ah
    mov Input, al  
    
    ret
_Cursor endp  
;================================================================
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
                 
    cmp ax, array_button[8]
    je MOUSE   
    
    cmp ax, array_button[6]
    je EXT      
    
    ; call Math_Operators           ; separated function for all +-*/ sqrt                             
    
    ; Clear Entry to reset position
    cmp ax, array_button[22]     
    je CL_ENTRY           
    
    cmp ax, array_button[26]
    je BSPC        
    
    ; maximum size of 30 
    mov si, inPtr
    cmp si, inLimit     
    jge L1                 
                 
    call _DetectKeys    
           
    ; Enter button
    ; cmp ax, array_button[70]
    ; je goto asciihex function 
    
    loop L1        
    
; Jump to function - - - - - - - - - - - - - - - - - - - - 
CL_ENTRY:
    call clrEntry 
    jmp L1

BSPC:
    call _BackSpace 
    jmp L1  
    
MOUSE:                                  
    call _Cursor
    mov ah, upperIn
    mov al, input
       
    jmp L2          
                                
EXT:      
    mov ax, 2
    int 33h
    ret   
_Calculator endp    

   
; FUNCTIONS =================================================== 
_DetectKeys proc
    ; This function get keys from keyboard to temporarily save into var
    xor ax, ax                   
    mov al, input                   ; this AL input print without AH value    
 
    mov si, inPtr   
    mov bl, tempStr[si-1]   
    
    sub al, 30h                     ; checks if left and right digit is 0
    sub bl, 30h
    cmp al, bl                      ; for some reason zero flag on, and disable multiple operand
    jz OP_END                       ; user now is forced to type only one operand per number
    
    cmp DigitF, 1                   ; 10000 is valid until user press + - ...
    je SKIP1                        ; DigitF : 0 = new term, 1 = continuous number 
    
    cmp al, 0                     ; if the next number is not > 0 then skip decrement
    jbe SKIP1
    cmp al, 9                     ; must not be digit 
    ja SKIP1                        ; while Digitf is 0 
    
    cmp bl, 0                       ; checks if the before digits is bigger than 0
    jne SKIP_DEC    
    
    dec inPtr                       ; if the first is 0 followed with non 0 then                        
    inc Update_Col
           
SKIP_DEC:                           ; if byte before is not number then flag 1
    or DigitF, 1                    ; new term 100+100                        
                     
SKIP1:           
    mov dh, String_y                ; row 4
    mov dl, Update_Col              ; column -1 each keys 
    call cursor          
    
    ;update column
    dec Update_Col 
     
    mov al, input                   ; correct variable to assign
                    
    mov si, inPtr                   
    mov tempStr[si], al             ; write into temp string    
    inc inPtr                              
                                       
    lea dx, tempStr                 ; display a byte
    call print   
    
    mov cx, 10          
    mov bl, "0"
ISDIGIT:                            ; check if its number
    cmp tempStr[si], bl           ; if the one before is a number
    je OP_END
    inc bl    
    loop ISDIGIT
    
    and DigitF, 0   
    
OP_END:   
    ret   
_DetectKeys endp    
;----------------------------------------------------------------
_BackSpace proc
    cmp inPtr, 0                    ; avoid si turn FF FF
    je NO_BSPC
    
    mov si, inPtr 
    
    cld  
    mov al, "$"             
    mov tempStr[si-1], al           ; replace current with $ 
                      
    xor dx, dx
    call cursor   
    lea dx, ScreenUI       
    call print 
    
    dec inPtr                       ; for string position
    inc Update_Col
    
    mov dh, String_y                ; row 4
    mov dl, Update_Col              ; to pointed column after increment
    call cursor         
     
    lea dx, tempStr                 ; display remaining string
    call print
    
    cmp inPtr, 0                    
    je PRINTZERO  
    
    mov si, inPtr 
            
    and DigitF, 0                   ; set DigitF to 0           
    mov cx, 10          
    mov bl, "0"
ISDIGIT2:                            ; check if its number
    cmp tempStr[si-1], bl           
    je ISNUMBER2
    inc bl    
    loop ISDIGIT2                    ; OPTIMISE THIS PART HERE <___________________
    
    jmp NO_BSPC 
    
ISNUMBER2:
    or DigitF, 1
    
    jmp NO_BSPC   
       
PRINTZERO:     
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
end main